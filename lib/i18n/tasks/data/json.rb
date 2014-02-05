require 'i18n/tasks/data/storage/file_storage'
require 'i18n/tasks/data/adapter/json_adapter'

module I18n::Tasks
  module Data
    class Json
      include Storage::FileStorage
      include Adapter::JsonAdapter
    end
  end
end
