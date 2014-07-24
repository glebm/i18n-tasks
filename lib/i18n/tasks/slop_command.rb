module I18n::Tasks::SlopCommand
  extend self

  def slop_command(name, attr, &block)
    proc {
      command name.tr('_', '-') do
        opts = attr[:opt]
        args = attr[:args]
        banner "Usage: i18n-tasks #{name} [options] #{args}" if args.present?
        desc = attr[:desc]
        description desc if desc
        if opts
          opts.each do |opt|
            on *[:short, :long, :desc, :conf].map { |k| opt[k] }.compact
          end
        end
        run { |opts, args| block.call(name, opts, args) }
      end
    }
  end

  def parse_slop_opts_args(opts, args)
    opts = opts.to_hash(true).reject { |k, v| v.nil? }
    opts.merge!(arguments: args) unless args.empty?
    opts
  end
end
