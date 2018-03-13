require 'i18n/tasks/scanners/file_scanner'
class MyCustomScanner < I18n::Tasks::Scanners::FileScanner
  include I18n::Tasks::Scanners::RelativeKeys
  include I18n::Tasks::Scanners::OccurrenceFromPosition

  # @return [Array<[absolute key, Results::Occurrence]>]
  def scan_file(path)
    text = read_file(path)
    text.scan(/^\s*=\s*page_title\b/).map do |_match|
      occurrence = occurrence_from_position(path, text, Regexp.last_match.offset(0).first)
      [absolute_key('.my_custom_scanner.title', path), occurrence]
    end
  end
end

::I18n::Tasks.add_scanner 'MyCustomScanner', only: %w(*.haml *.slim)
