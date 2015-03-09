# coding: utf-8
require 'fileutils'
require 'yaml'
require_relative 'capture_std'
require 'i18n/tasks/commands'
require 'i18n/tasks/cli'

module TestCodebase
  include CaptureStd
  extend self
  AT = 'tmp/test_codebase'

  def i18n_task(*args)
    in_test_app_dir do
      ::I18n::Tasks::BaseTask.new(*args)
    end
  end

  def run_cmd(name, *args)
    capture_stdout { capture_stderr { in_test_app_dir {
      run_cli(name, *args)
    } } }
  end

  def run_cmd_capture_stderr(name, *args)
    capture_stderr { capture_stdout { in_test_app_dir {
      run_cli(name, *args)
    } } }
  end

  def run_cli(name, *args)
    i18n_cli.run([name, *args])
  end

  def i18n_cli
    in_test_app_dir { ::I18n::Tasks::CLI.new }
  end

  def setup(files = {})
    FileUtils.mkdir_p AT
    in_test_app_dir do
      files.each do |path, content|
        FileUtils.mkdir_p File.dirname(path)
        File.open(path, 'w') { |f| f.write(content) }
      end
    end
  end

  def teardown
    FileUtils.rm_rf AT
  end

  def rake_result(task, *args)
    in_test_app_dir {
      rake_task = Rake::Task[task]
      rake_task.reenable
      capture_stdout { rake_task.invoke(*args) }
    }
  end

  def in_test_app_dir
    return yield if @in_dir
    begin
      pwd = Dir.pwd
      Dir.chdir AT
      @in_dir = true
      yield
    ensure
      Dir.chdir pwd
      @in_dir = false
    end
  end
end


