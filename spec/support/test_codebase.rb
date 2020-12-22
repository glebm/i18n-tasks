# frozen_string_literal: true

require 'fileutils'
require 'yaml'
require_relative 'capture_std'
require 'i18n/tasks/commands'
require 'i18n/tasks/cli'

module TestCodebase
  AT = 'tmp/test_codebase'

  class << self
    include CaptureStd

    def i18n_task(*args)
      in_test_app_dir do
        ::I18n::Tasks::BaseTask.new(*args)
      end
    end

    def run_cmd(name, *args)
      capture_stdout do
        capture_stderr do
          in_test_app_dir do
            run_cli(name, *args)
          end
        end
      end
    end

    def run_cmd_capture_stdout_and_result(name, *args)
      result = nil
      out = capture_stdout do
        capture_stderr do
          in_test_app_dir do
            result = run_cli(name, *args)
          end
        end
      end
      [out, result]
    end

    def run_cmd_capture_stderr(name, *args)
      capture_stderr do
        capture_stdout do
          in_test_app_dir do
            run_cli(name, *args)
          end
        end
      end
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
      in_test_app_dir do
        rake_task = Rake::Task[task]
        rake_task.reenable
        capture_stdout { rake_task.invoke(*args) }
      end
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
end
