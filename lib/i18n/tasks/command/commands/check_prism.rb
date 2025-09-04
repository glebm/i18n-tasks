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
            results[label] = keys.each_with_object({}) do |node, h|
              full_key = node.full_key(root: false)
              h[full_key] = node.data[:occurrences]
            end
          end

          # restore original config and caches
          i18n.config[:search] = orig_search
          i18n.instance_variable_set(:@scanner, nil)
          i18n.instance_variable_set(:@search_config, nil)
          i18n.instance_variable_set(:@keys_used_in_source_tree, nil)

          default_keys = results[:default].keys
          prism_keys = results[:prism].keys

          only_default = (default_keys - prism_keys).sort
          only_prism = (prism_keys - default_keys).sort
          both = (default_keys & prism_keys).sort

          File.open(report_path, "w") do |f|
            f.puts "# i18n-tasks check_prism report"
            f.puts "Generated at: #{now.utc}"
            f.puts "Prism mode: #{chosen_prism_mode}"
            f.puts "Gem version: #{I18n::Tasks::VERSION}"
            f.puts ""
            f.puts "Summary"
            f.puts "- total keys (default parser): #{default_keys.size}"
            f.puts "- total keys (prism): #{prism_keys.size}"
            f.puts "- keys in both: #{both.size}"
            f.puts "- keys only in default parser: #{only_default.size}"
            f.puts "- keys only in prism: #{only_prism.size}"
            f.puts ""

            unless only_default.empty?
              f.puts "## Keys found by the default parser but NOT by Prism (#{only_default.size})"
              only_default.each do |k|
                f.puts "\n### #{k}"
                results[:default][k].first(5).each do |occ|
                  src = (occ.raw_key || k).to_s
                  line = (occ.line || "").strip
                  highlighted = line.gsub(src) { |m| "`#{m}`" }
                  f.puts "- #{occ.path}:#{occ.line_num} `#{src}` — #{highlighted}"
                end
              end
            end

            unless only_prism.empty?
              f.puts "## Keys found by Prism but NOT by the default parser (#{only_prism.size})"
              only_prism.each do |k|
                f.puts "\n### #{k}"
                results[:prism][k].each do |occ|
                  src = (occ.raw_key || k).to_s
                  line = (occ.line || "").strip
                  highlighted = line.gsub(src) { |m| "`#{m}`" }
                  f.puts "- #{occ.path}:#{occ.line_num} `#{src}` — #{highlighted}"
                end
              end
            end

            f.puts "\n## Notes"
            f.puts "- This report compares keys discovered by the project default parser and by Prism (rails mode)."
          end

          log_stderr "Wrote check_prism report: #{report_path}"
          puts File.read(report_path)
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
