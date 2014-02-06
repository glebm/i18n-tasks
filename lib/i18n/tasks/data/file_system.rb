require 'i18n/tasks/data/storage/file_storage'
require 'i18n/tasks/data/adapter/json_adapter'
require 'i18n/tasks/data/adapter/yaml_adapter'

module I18n::Tasks
  module Data
    class FileSystem
      include Storage::FileStorage
      register_adapter '*.yml', Adapter::YamlAdapter
      register_adapter '*.json', Adapter::JsonAdapter
    end
  end
end
