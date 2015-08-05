if ENV['TRAVIS']
  require 'codeclimate_batch'
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.configuration.git_dir = File.dirname(__FILE__)
  CodeclimateBatch.start
else
  SimpleCov.start do
    formatter SimpleCov::Formatter::HTMLFormatter
  end
end
