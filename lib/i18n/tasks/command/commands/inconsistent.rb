# frozen_string_literal: true

module I18n::Tasks
  module Command
    module Commands
      module Inconsistent
        include Command::Collection

        cmd :check_consistent_interpolations,
            pos: '[locale ...]',
            desc: t('i18n_tasks.cmd.desc.check_consistent_interpolations'),
            args: %i[locales out_format]

        def check_consistent_interpolations(opt = {})
          forest = i18n.inconsistent_interpolation(opt.slice(:locales, :base_locale))
          print_forest forest, opt, :inconsistent_interpolation
          :exit_1 unless forest.empty?
        end
      end
    end
  end
end
