require 'i18n/tasks'
require 'i18n/tasks/commands'
require 'optparse'

class I18n::Tasks::CLI
  include ::I18n::Tasks::Logging

  def self.start(argv)
    new.start(argv)
  end

  def initialize
  end

  def start(argv)
    auto_output_coloring do
      begin
        run(argv)
      rescue OptionParser::ParseError => e
        error e.message, 64
      rescue I18n::Tasks::CommandError => e
        log_verbose e.backtrace * "\n"
        error e.message, 78
      rescue Errno::EPIPE
        # ignore Errno::EPIPE which is throw when pipe breaks, e.g.:
        # i18n-tasks missing | head
        exit 1
      end
    end
  rescue ExecutionError => e
    exit e.exit_code
  end

  def run(argv)
    name, *options = parse_options(argv)
    context.run(name, *options)
  end

  def context
    @context ||= ::I18n::Tasks::Commands.new.tap(&:set_internal_locale!)
  end

  def commands
    @commands ||= ::I18n::Tasks::Commands.cmds.transform_keys { |k| k.to_s.tr('_', '-') }
  end

  def parse_options(argv)
    command = parse_command!(argv)
    options = optparse_options!(command, argv)
    options = parse_values!(command, options, argv)
    [command.tr('-', '_'), options.update(arguments: argv)]
  end

  def parse_command!(argv)
    if argv[0] && !argv[0].start_with?('-')
      if commands.keys.include?(argv[0])
        argv.shift
      else
        error "Command unknown: #{argv[0]}", 64
      end
    end
  end

  def optparse_options!(command, argv)
    argv << '--help' if command.nil? && argv.empty?

    unless command
      OptionParser.new("Usage: #{program_name} [command] [options]") do |op|
        op.on('-v', '--version', 'Print the version') do
          puts I18n::Tasks::VERSION
          exit
        end

        op.on('-h', '--help', 'Show this message') do
          $stderr.puts op
          exit
        end

        op.separator ''
        op.separator 'Available commands:'
        op.separator ''
        commands.each do |cmd, cmd_conf|
          op.separator "    #{cmd.ljust(op.summary_width + 1, ' ')}#{try_call cmd_conf[:desc]}"
        end
        op.separator ''
        op.separator 'See `i18n-tasks <command> --help` for more information on a specific command.'
      end.parse!(argv)
    end

    cmd_conf = commands[command]
    flags    = (cmd_conf[:opt] || []).dup
    options  = {}
    OptionParser.new("Usage: #{program_name} #{command} [options] #{cmd_conf[:args]}".strip) do |op|
      flags.each do |flag|
        args = flag.dup
        args.map! { |v| try_call v }
        conf = args.extract_options!
        if conf.key?(:default)
          args[-1] = [args[-1], I18n.t('i18n_tasks.cmd.args.default_text', value: conf[:default])] * '. '
        end
        op.on(*args) { |v| options[option_name(flag)] = v }
      end
      op.on('-h', '--help', 'Show this message') do
        $stderr.puts op
        exit
      end
    end.parse!(argv)

    options
  end

  private

  def parse_values!(command, options, argv)
    (commands[command][:opt] || []).each do |flag|
      name          = option_name flag
      options[name] = parse_value flag, options[name], argv, self.context
    end
    options
  end

  def parse_value(flag, val, argv, context)
    conf = flag.last.is_a?(Hash) ? flag.last : {}
    val  = Array(val) + Array(argv) if conf[:consume_positional]
    val  = conf[:default] if val.nil? && conf.key?(:default)
    val  = conf[:parser].call(val, context) if conf.key?(:parser)
    val
  end

  def option_name(flag)
    flag.detect { |f| f.start_with?('--') }.sub(/\A--/, '').sub(/[^\-\w].*\z/, '').to_sym
  end

  def try_call(v)
    if v.respond_to? :call
      v.call
    else
      v
    end
  end

  def error(message, exit_code)
    log_error message
    fail ExecutionError.new(message, exit_code)
  end

  class ExecutionError < Exception
    attr_reader :exit_code

    def initialize(message, exit_code)
      super(message)
      @exit_code = exit_code
    end
  end

  def auto_output_coloring(coloring = ENV['I18N_TASKS_COLOR'] || STDOUT.isatty)
    coloring_was             = Term::ANSIColor.coloring?
    Term::ANSIColor.coloring = coloring
    yield
  ensure
    Term::ANSIColor.coloring = coloring_was
  end

end
