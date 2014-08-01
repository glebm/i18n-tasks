module I18n::Tasks::SlopCommand
  extend self

  def slop_command(name, attr, &block)
    proc {
      command name.tr('_', '-') do
        args = attr[:args]
        banner "Usage: i18n-tasks #{name} [options] #{args}" if args.present?
        desc = attr[:desc]
        desc = desc.call if desc.respond_to?(:call)
        description desc if desc
        attr[:opt].try :each do |opt|
          on *opt.values_at(:short, :long, :desc, :conf).compact.map { |v| v.respond_to?(:call) ? v.call : v }
        end
        run { |slop_opts, slop_args|
          slop_opts = slop_opts.to_hash(true).reject { |k, v| v.nil? }
          slop_opts.merge!(arguments: slop_args) unless slop_args.empty?
          block.call name, slop_opts
        }
      end
    }
  end

  def parse_opts!(opts, opts_conf, context)
    return if !opts_conf
    opts_conf.each do |opt_conf|
      parse = opt_conf[:parse]
      if parse
        key = opt_conf[:long].to_s.sub(/=\z/, '').to_sym
        if parse.respond_to?(:call)
          context.instance_exec opts, key, &parse
        elsif Symbol === parse
          context.instance_exec do
            send parse, opts, key
          end
        end
      end
    end
  end
end
