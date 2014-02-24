require 'i18n/tasks/data/file_system'

module I18n::Tasks
  module Data
    class Yaml < FileSystem
      def initialize(*args)
        super
        I18n::Tasks.warn_deprecated "data.adapter set to 'yaml'. please use 'file_system' instead"
      end
      register_adapter '*.yml', Adapter::YamlAdapter
    end
  end
end
