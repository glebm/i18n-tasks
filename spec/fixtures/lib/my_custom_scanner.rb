require 'i18n/tasks/scanners/pattern_scanner'
class MyCustomScanner < I18n::Tasks::Scanners::PatternScanner
  def scan_file(path)
    text = read_file(path)
    text.scan(/^\s*=\s*page_title\b/).map do |_match|
      location = src_location(path, text, Regexp.last_match.offset(0).first)
      [absolute_key('.my_custom_scanner.title', path, location), location]
    end
  end
end
