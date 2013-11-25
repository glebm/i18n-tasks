require 'i18n/tasks/reports/base'
require 'fileutils'

module I18n::Tasks::Reports
  class Spreadsheet < Base

    def save_report(path = 'tmp/i18n-report.xlsx')
      p = Axlsx::Package.new
      add_missing_sheet p.workbook
      add_unused_sheet p.workbook
      p.use_shared_strings = true
      FileUtils.mkpath(File.dirname(path))
      p.serialize(path)
      $stderr.puts Term::ANSIColor.green "Saved to #{path}"
    end

    private

    def add_missing_sheet(wb)
      recs = task.untranslated_keys
      wb.styles do |s|
        type_cell = s.add_style :alignment => {:horizontal => :center}
        locale_cell  = s.add_style :alignment => {:horizontal => :center}
        regular_style = s.add_style
        wb.add_worksheet(name: missing_title(recs)) { |sheet|
          sheet.page_setup.fit_to :width => 1
          sheet.add_row ['Type', 'Locale', 'Key', 'Base Value']
          style_header sheet
          recs.each do |rec|
            sheet.add_row [missing_types[rec[:type]][:summary], rec[:locale], rec[:key], rec[:base_value]],
            styles: [type_cell, locale_cell, regular_style, regular_style]
          end
        }
      end
    end

    def add_unused_sheet(wb)
      recs = task.unused_keys
      wb.add_worksheet name: unused_title(recs) do |sheet|
        sheet.add_row ['Key', 'Base Value']
        style_header sheet
        recs.each do |rec|
          sheet.add_row rec
        end
      end
    end

    private
    def style_header(sheet)
      border_bottom = sheet.workbook.styles.add_style(border: {style: :thin, color: '000000', edges: [:bottom]})
      sheet.rows.first.style = border_bottom
    end
  end
end
