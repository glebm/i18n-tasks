# An i18n-tasks plugin to test that the plugin system works.
module TestI18nPlugin
  include ::I18n::Tasks::Command::Collection

  cmd :greet,
      desc: 'print "Hello, %{name}"',
      args: [['-n', '--name NAME', 'name']]

  def greet(opts = {})
    puts "Hello, #{opts[:name]}"
  end
end
