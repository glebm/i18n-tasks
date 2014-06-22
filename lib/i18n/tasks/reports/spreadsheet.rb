# coding: utf-8
require 'i18n/tasks/reports/base'
require 'fileutils'

module I18n::Tasks::Reports
  class Spreadsheet < Base

    def save_report(path = nil)
      path = 'tmp/i18n-report.xlsx' if path.blank?
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
      tree = task.missing_keys
      wb.styles do |s|
        type_cell = s.add_style :alignment => {:horizontal => :center}
        locale_cell  = s.add_style :alignment => {:horizontal => :center}
        regular_style = s.add_style
        wb.add_worksheet(name: missing_title(tree)) { |sheet|
          sheet.page_setup.fit_to :width => 1
          sheet.add_row ['Type', 'Locale', 'Key', 'Base Value']
          style_header sheet
          tree.keys do |key, node|
            locale, type = node.root.data[:locale], node.data[:type]
            sheet.add_row [missing_types[type][:summary], locale, key, task.t(key)],
            styles: [type_cell, locale_cell, regular_style, regular_style]
          end
        }
      end
    end

    def add_unused_sheet(wb)
      keys = task.unused_keys.root_key_values.sort { |a, b| a[0] != b[0] ? a[0] <=> b[0] : a[1] <=> b[1] }
      wb.add_worksheet name: unused_title(keys) do |sheet|
        sheet.add_row ['Locale', 'Key', 'Value']
        style_header sheet
        keys.each do |locale_k_v|
          sheet.add_row locale_k_v
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
