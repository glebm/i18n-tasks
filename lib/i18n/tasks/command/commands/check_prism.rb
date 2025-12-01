# frozen_string_literal: true

module I18n::Tasks
  module Command
    module Commands
      module CheckPrism
        include Command::Collection

        arg :prism_mode,
          "--prism_mode MODE",
          "Prism parser mode: 'rails' or 'ruby'. Defaults to 'rails' if Rails is available in the project, otherwise 'ruby'."

        cmd :check_prism,
          desc: t("i18n_tasks.cmd.desc.check_prism"),
          args: %i[prism_mode]

        # Run both the default (Parser-based) and the Prism-enabled scanning
        # and produce a plain-text report in tmp/i18n_tasks_check_prism.md suitable
        # for pasting into an issue.
        def check_prism(opt = {})
          now = Time.now
          report_path = File.join(Dir.pwd, "tmp", "i18n_tasks_check_prism.md")
          FileUtils.mkdir_p(File.dirname(report_path))

          # keep original search config and clear caches helper
          orig_search = (i18n.config[:search] || {}).dup

          results = {}

          # determine prism mode: use provided opt or default to rails when Rails present
          chosen_prism_mode = (opt[:prism_mode].presence || (rails_available? ? "rails" : "ruby")).to_s
          unless %w[rails ruby].include?(chosen_prism_mode)
            fail CommandError, "--prism-mode must be 'rails' or 'ruby'"
          end

          {default: nil, prism: chosen_prism_mode}.each do |label, prism_mode|
            i18n.config[:search] = orig_search.merge(prism: prism_mode)
            # clear caches used by UsedKeys
            i18n.instance_variable_set(:@scanner, nil)
            i18n.instance_variable_set(:@search_config, nil)
            i18n.instance_variable_set(:@keys_used_in_source_tree, nil)

            tree = i18n.used_in_source_tree
            keys = tree.nodes.select { |n| n.data[:occurrences].present? }
            results[label] = {
              keys: keys.each_with_object({}) do |node, h|
                full_key = node.full_key(root: false)
                h[full_key] = node.data[:occurrences]
              end,
              # Build a set of all keys including candidate keys
              all_keys: keys.flat_map do |node|
                full_key = node.full_key(root: false)
                candidates = node.data[:occurrences].flat_map { |occ| occ.candidate_keys || [] }
                [full_key] + candidates
              end.uniq
            }
          end

          # restore original config and caches
          i18n.config[:search] = orig_search
          i18n.instance_variable_set(:@scanner, nil)
          i18n.instance_variable_set(:@search_config, nil)
          i18n.instance_variable_set(:@keys_used_in_source_tree, nil)

          default_keys = results[:default][:keys].keys
          prism_keys = results[:prism][:keys].keys

          # Use all_keys (including candidate_keys) for comparison
          default_all_keys = results[:default][:all_keys]
          prism_all_keys = results[:prism][:all_keys]

          # Calculate differences, but filter out keys that are candidate keys in the other parser
          only_default_raw = (default_all_keys - prism_all_keys)
          only_prism_raw = (prism_all_keys - default_all_keys)

          # Filter out keys that exist as candidates in the other parser
          only_default = only_default_raw.reject do |key|
            # Check if this key is a candidate in prism results
            results[:prism][:keys].any? { |_main_key, occs| occs.any? { |occ| occ.candidate_keys&.include?(key) } }
          end.sort

          only_prism = only_prism_raw.reject do |key|
            # Check if this key is a candidate in default results
            results[:default][:keys].any? { |_main_key, occs| occs.any? { |occ| occ.candidate_keys&.include?(key) } }
          end.sort

          both = (default_all_keys & prism_all_keys).sort

          File.open(report_path, "w") do |f|
            f.puts "# i18n-tasks check_prism report"
            f.puts "Generated at: #{now.utc}"
            f.puts "Prism mode: #{chosen_prism_mode}"
            f.puts "Gem version: #{I18n::Tasks::VERSION}"
            f.puts ""
            f.puts "Summary"
            f.puts "- total keys (default parser): #{default_keys.size}"
            f.puts "- total keys (prism): #{prism_keys.size}"
            f.puts "- total keys including candidates (default parser): #{default_all_keys.size}"
            f.puts "- total keys including candidates (prism): #{prism_all_keys.size}"
            f.puts "- keys in both: #{both.size}"
            f.puts "- keys only in default parser: #{only_default.size}"
            f.puts "- keys only in prism: #{only_prism.size}"
            f.puts ""

            unless only_default.empty?
              f.puts "## Keys found by the default parser but NOT by Prism (#{only_default.size})"
              only_default.each do |k|
                f.puts "\n### #{k}"
                # Find occurrences where this key appears (either as main key or candidate)
                occs = results[:default][:keys][k] || []
                if occs.empty?
                  # This key might be a candidate key, find which main key has it
                  results[:default][:keys].each do |main_key, main_occs|
                    main_occs.each do |occ|
                      if occ.candidate_keys&.include?(k)
                        occs << occ
                      end
                    end
                  end
                end
                occs.first(5).each do |occ|
                  src = (occ.raw_key || k).to_s
                  line = (occ.line || "").strip
                  highlighted = line.gsub(src) { |m| "`#{m}`" }
                  candidate_info = occ.candidate_keys ? " (candidates: #{occ.candidate_keys.join(", ")})" : ""
                  f.puts "- #{occ.path}:#{occ.line_num} `#{src}`#{candidate_info} — #{highlighted}"
                end
              end
            end

            unless only_prism.empty?
              f.puts "## Keys found by Prism but NOT by the default parser (#{only_prism.size})"
              only_prism.each do |k|
                f.puts "\n### #{k}"
                # Find occurrences where this key appears (either as main key or candidate)
                occs = results[:prism][:keys][k] || []
                if occs.empty?
                  # This key might be a candidate key, find which main key has it
                  results[:prism][:keys].each do |main_key, main_occs|
                    main_occs.each do |occ|
                      if occ.candidate_keys&.include?(k)
                        occs << occ
                      end
                    end
                  end
                end
                occs.each do |occ|
                  src = (occ.raw_key || k).to_s
                  line = (occ.line || "").strip
                  highlighted = line.gsub(src) { |m| "`#{m}`" }
                  candidate_info = occ.candidate_keys ? " (candidates: #{occ.candidate_keys.join(", ")})" : ""
                  f.puts "- #{occ.path}:#{occ.line_num} `#{src}`#{candidate_info} — #{highlighted}"
                end
              end
            end

            f.puts "\n## Notes"
            f.puts "- This report compares keys discovered by the project default parser and by Prism (#{chosen_prism_mode} mode)."
          end

          log_stderr "Wrote check_prism report: #{report_path}"
        end

        private

        def rails_available?
          return true if defined?(Rails)
          return true if Gem.loaded_specs.key?("rails")
          lock = File.join(Dir.pwd, "Gemfile.lock")
          return false unless File.exist?(lock)
          File.read(lock).lines.any? { |l| l.strip.start_with?("rails ") || l.strip =~ /^rails \(/ }
        rescue
          false
        end
      end
    end
  end
end
