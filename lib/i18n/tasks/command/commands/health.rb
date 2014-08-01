module I18n::Tasks
  module Command
    module Commands
      module Health
        include Command::Collection

        cmd :health,
            args: '[locale ...]',
            desc: I18n.t('i18n_tasks.cmd.desc.health'),
            opt:  cmd_opts(:locales, :out_format)

        def health(opt = {})
          forest = i18n.data_forest(opt[:locales])
          stats  = i18n.forest_stats(forest)
          if stats[:key_count].zero?
            raise CommandError.new I18n.t('i18n_tasks.health.no_keys_detected')
          end
          terminal_report.forest_stats forest, stats
          missing opt
          unused opt
        end
      end
    end
  end
end
