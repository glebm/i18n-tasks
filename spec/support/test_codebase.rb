# coding: utf-8
require 'fileutils'
require 'yaml'
require_relative 'capture_std'

module TestCodebase
  include CaptureStd
  extend self
  AT = 'tmp/test_codebase'

  def i18n_task(*args)
    TestCodebase.in_test_app_dir do
      ::I18n::Tasks::BaseTask.new(*args)
    end
  end

  def i18n_cmd(*args)
    TestCodebase.in_test_app_dir do
      ::I18n::Tasks::Commands.new(*args)
    end
  end

  def run_cmd(name, *args, &block)
    in_test_app_dir do
      capture_stdout { i18n_cmd.send(name, *args, &block) }
    end
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

  def in_test_app_dir(&block)
    return block.call if @in_dir
    begin
      pwd = Dir.pwd
      Dir.chdir AT
      @in_dir = true
      block.call
    ensure
      Dir.chdir pwd
      @in_dir = false
    end
  end
end


