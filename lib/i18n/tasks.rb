# coding: utf-8
# define all the modules to be able to use ::
module I18n
  module Tasks

    def self.gem_path
      File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
    end

    module Data
    end
  end
end


require 'active_support/core_ext/hash'
require 'active_support/core_ext/string'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/object/blank'
require 'term/ansicolor'
require 'erubis'

require 'i18n/tasks/version'
require 'i18n/tasks/base_task'

# Add internal locale data to i18n gem load path
require 'i18n'
Dir[File.join(I18n::Tasks.gem_path, 'config', 'locales', '*.yml')].each do |locale_file|
  I18n.config.load_path << locale_file
end
