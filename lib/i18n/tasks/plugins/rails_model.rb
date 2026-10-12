# frozen_string_literal: true

require "set"
require_relative "base_plugin"

module I18n
  module Tasks
    module Plugins
      # Plugin that fixes two limitations of the Prism scanner's Rails model localization support:
      #
      # 1. STI fallback: when a child class (e.g. Car < Vehicle < ApplicationRecord) calls
      #    `human_attribute_name` or `model_name.human`, Rails falls back up the inheritance chain
      #    if a key is not found for the child. This plugin adds the ancestor keys as candidate_keys
      #    so i18n-tasks doesn't report parent-class translations as unused.
      #
      # 2. ActiveModel namespace: classes that include ActiveModel::Model (or a module that
      #    transitively includes it) but are not ActiveRecord models must use `activemodel.*`
      #    keys, not `activerecord.*`. This plugin corrects the namespace when it detects the
      #    class is an ActiveModel-only class.
      #
      # Configuration in i18n-tasks.yml:
      #
      #   plugins:
      #     rails_model:
      #       models_paths:
      #         - app/models/**/*.rb
      #       active_model_includes:   # optional — extend the default [ActiveModel::Model]
      #         - AttrJson::Model      # any module that transitively includes ActiveModel::Model
      #
      class RailsModel < BasePlugin
        AR_ROOTS = %w[ApplicationRecord ActiveRecord::Base].freeze

        # Patterns that unconditionally mark a class as ActiveModel-only.
        # `extend ActiveModel::Translation` is the standard Rails way to add
        # human_attribute_name / model_name support to a plain Ruby class.
        AM_DEFAULT_PATTERNS = [
          /\binclude\s+ActiveModel::Model\b/,
          /\bextend\s+ActiveModel::Translation\b/,
        ].freeze

        def initialize(config = {})
          paths          = config.fetch(:models_paths, ["app/models/**/*.rb"])
          extra_includes = Array(config.fetch(:active_model_includes, []))
          @am_pattern    = Regexp.union(
            AM_DEFAULT_PATTERNS +
            extra_includes.map { |mod| /\binclude\s+#{Regexp.escape(mod)}\b/ }
          )
          @model_index = build_model_index(Array(paths))
        end

        # Hook: :resolve_model_key
        # Receives: { key:, candidate_keys: } plus model_constant_name:, call_type:, attribute_name:
        # Returns: potentially modified { key:, candidate_keys: }
        register_hook :resolve_model_key do |result, model_constant_name:, call_type:, attribute_name: nil, **|
          info = @model_index[model_constant_name]
          next result unless info

          key = result[:key]
          candidate_keys = result[:candidate_keys].dup

          if info[:active_model] && key.start_with?("activerecord.")
            key = key.sub("activerecord.", "activemodel.")
            candidate_keys = candidate_keys.map { |k| k.sub("activerecord.", "activemodel.") }
          end

          if info[:active_record]
            sti_chain(model_constant_name).each do |parent_name|
              parent_key = ActiveSupport::Inflector.underscore(parent_name)
              candidate_keys << case call_type
              when :human_attribute_name
                separator = attribute_name&.include?(".") ? "/" : "."
                "activerecord.attributes.#{parent_key}#{separator}#{attribute_name}"
              when :model_name
                "activerecord.models.#{parent_key}"
              end
            end
            candidate_keys.compact!
          end

          {key: key, candidate_keys: candidate_keys}
        end

        private

        def build_model_index(path_patterns)
          index = {}
          Dir.glob(path_patterns).each do |file_path|
            index_file(file_path, index)
          end
          resolve_active_record!(index)
          resolve_active_model!(index)
          index
        end

        def index_file(file_path, index)
          content = File.read(file_path)
          content.scan(/^\s*class\s+(\w+)(?:\s*<\s*(\S+))?/) do |class_name, parent_name|
            qualified  = qualified_class_name(content, class_name)
            is_ar_root = AR_ROOTS.include?(parent_name)
            is_am      = @am_pattern.match?(content) &&
                         !content.match?(/\b(?:ApplicationRecord|ActiveRecord::Base)\b/)
            index[qualified] = {
              parent:        parent_name&.split("::")&.last,
              active_model:  is_am,
              ar_root:       is_ar_root,
              active_record: false # resolved below
            }
          end
        end

        # Derive the fully qualified Ruby constant name by collecting module
        # declarations that appear before the class definition in the file.
        # Works for both top-level classes ("OperationalRack") and module-nested
        # classes ("AttrJsonModels::LocationCapacity::Power").
        def qualified_class_name(content, class_name)
          modules = []
          content.each_line do |line|
            break if line.match?(/^\s*class\s+#{Regexp.escape(class_name)}\b/)
            modules << Regexp.last_match(1) if line.match(/^\s*module\s+(\S+)/)
          end
          ([*modules, class_name]).join("::")
        end

        def resolve_active_record!(index)
          index.each_key { |name| index[name][:active_record] = ar_ancestor?(name, index, Set.new) }
        end

        def resolve_active_model!(index)
          index.each_key { |name| index[name][:active_model] ||= am_ancestor?(name, index, Set.new) }
        end

        def am_ancestor?(name, index, visited)
          return false if visited.include?(name)
          visited << name
          info = index[name]
          return false unless info
          return true if info[:active_model]

          am_ancestor?(info[:parent].to_s, index, visited)
        end

        def ar_ancestor?(name, index, visited)
          return false if visited.include?(name)
          visited << name
          info = index[name]
          return false unless info
          return true if info[:ar_root]

          ar_ancestor?(info[:parent].to_s, index, visited)
        end

        def sti_chain(class_name)
          chain = []
          visited = Set.new([class_name])
          current = @model_index.dig(class_name, :parent)
          while current && !visited.include?(current)
            info = @model_index[current]
            break unless info
            break if AR_ROOTS.include?(current)  # skip framework base classes

            chain << current
            visited << current
            break if info[:ar_root]  # include this domain class, then stop

            current = info[:parent]
          end
          chain
        end
      end
    end
  end
end
