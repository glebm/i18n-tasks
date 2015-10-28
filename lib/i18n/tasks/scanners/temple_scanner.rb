require 'temple'

module I18n::Tasks::Scanners
  # A base class for {Temple}-based scanners.
  #
  # @abstract
  # @since 0.9.0
  class TempleScanner < FileScanner
    def initialize(gem_name:, suggested_gem_version:, class_name:, requires:, **args)
      super(args)
      @gem_name     = gem_name
      @suggested_gem_version  = suggested_gem_version
      @class_name   = class_name
      @requires     = requires
      @parser_class = nil
    end

    protected

    # @return [Class<Temple::Parser>]
    def parser_class
      @parser_class ||= begin
        begin
          Array(@requires).each { |dependency| require dependency }
        rescue LoadError => e
          raise ::I18n::Tasks::CommandError.new(
                    e, "#{e.message}: Please add `gem '#{@gem_name}', '#{@suggested_gem_version}'` to the Gemfile.")
        end
        ActiveSupport::Inflector.constantize(@class_name)
      end
    end
  end
end
