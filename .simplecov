SimpleCov.start do
  formatter(
      if ENV['TRAVIS']
        require 'codeclimate-test-reporter'
        SimpleCov::Formatter::MultiFormatter[
            SimpleCov::Formatter::HTMLFormatter,
            CodeClimate::TestReporter::Formatter
        ]
      else
        SimpleCov::Formatter::HTMLFormatter
      end)
end
