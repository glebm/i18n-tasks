require 'fileutils'
require 'yaml'

module TestCodebase
  extend self
  AT = 'tmp/test_codebase'


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

  def rake_result(task)
    in_test_app_dir {
      rake_task = Rake::Task[task]
      rake_task.reenable
      capture_stdout { rake_task.invoke }
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

  def capture_stderr
    err, $stderr = $stderr, StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = err
  end

  def capture_stdout
    out, $stdout = $stdout, StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = out
  end
end
