# frozen_string_literal: true

require "rexml/document"

def escape_property(value)
  value.gsub("%", "%25").gsub("\r", "%0D").gsub("\n", "%0A").gsub(":", "%3A").gsub(",", "%2C")
end

def escape_data(value)
  value.gsub("%", "%25").gsub("\r", "%0D").gsub("\n", "%0A")
end

reports = Dir.glob(File.join(ARGV.fetch(0, "test-results"), "**", "*.xml")).sort
summary = ["## RSpec results", ""]

if reports.empty?
  summary << "No JUnit reports were uploaded."
  puts "::warning::No JUnit reports were uploaded."
else
  summary << "| Ruby | Tests | Failures | Errors | Skipped |"
  summary << "| --- | ---: | ---: | ---: | ---: |"

  reports.each do |report|
    ruby_version = File.basename(File.dirname(report)).delete_prefix("test-results-")
    document = REXML::Document.new(File.read(report))
    cases = []
    document.elements.each("//testcase") { |test_case| cases << test_case }

    failed = cases.count { |test_case| test_case.elements["failure"] }
    errors = cases.count { |test_case| test_case.elements["error"] }
    skipped = cases.count { |test_case| test_case.elements["skipped"] }
    summary << "| #{ruby_version} | #{cases.size} | #{failed} | #{errors} | #{skipped} |"

    cases.each do |test_case|
      %w[failure error].each do |result|
        issue = test_case.elements[result]
        next unless issue

        name = [test_case.attributes["classname"], test_case.attributes["name"]].compact.join(" ")
        message = [issue.attributes["message"], issue.text].compact.reject(&:empty?).join(": ")
        location = test_case.attributes["file"]
        details = "#{ruby_version}: #{name} - #{message}"
        summary << "- **#{ruby_version}** `#{name}`: #{message.to_s.gsub("\n", " ")}"

        properties = ["title=RSpec #{result}"]
        properties << "file=#{location}" if location
        escaped_properties = properties.map { |property| escape_property(property) }.join(",")
        puts "::error #{escaped_properties}::#{escape_data(details)}"
      end
    end
  end
end

if (summary_path = ENV["GITHUB_STEP_SUMMARY"])
  File.open(summary_path, "a") { |file| file.puts(summary.join("\n")) }
else
  puts summary.join("\n")
end
