# frozen_string_literal: true

module I18n::Tasks
  module Command
    module Commands
      module Translate
        include Command::Collection
        include I18n::Tasks::KeyPatternMatching

        cmd :translate,
            pos: '[pattern]',
            desc: t('i18n_tasks.cmd.desc.translate'),
            args: [:locale, :locale_to_translate_from, arg(:data_format).from(1), :translation_backend]

        def translate(opts = {})
          forest = i18n.tree(opts[:from])
          forest.set_root_key!(opts[:locale])

          if opts[:pattern]
            pattern_re = i18n.compile_key_pattern(opts[:pattern])
            forest.select_keys! { |full_key, _node| full_key =~ pattern_re }
          end

          backend = opts[:backend]&.to_sym || i18n.translation_config[:backend] || :google

          puts forest

          print_forest i18n.translate_forest(forest, from: opts[:from], backend: backend), opts
        end
      end
    end
  end
end
