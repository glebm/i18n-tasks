require 'fileutils'
module TestCodebase
  extend self
  AT = 'tmp/test_codebase'

  DEFAULTS = {
      'config/locales/en.yml' => {'en' => {}}.to_yaml,
      'config/locales/es.yml' => {'es' => {}}.to_yaml
  }

  def setup(files)
    FileUtils.mkdir_p AT
    in_test_app_dir do
      DEFAULTS.merge(files).each do |path, content|
        FileUtils.mkdir_p File.dirname(path)
        File.open(path, 'w') { |f| f.write(content) }
      end
    end
  end

  def teardown
    FileUtils.rm_rf AT
  end

  def rake_result(task)
    in_test_app_dir {
      rake_task = Rake::Task[task]
      rake_task.reenable
      capture_stdout { rake_task.invoke }
    }
  end

  def in_test_app_dir(&block)
    pwd = Dir.pwd
    Dir.chdir AT
    block.call
  ensure
    Dir.chdir pwd
  end

  private
  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    out.string
  ensure
    $stdout = STDOUT
  end
end
