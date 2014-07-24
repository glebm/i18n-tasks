module I18n::Tasks
  module HtmlKeys
    extend self
    HTML_KEY_PATTERN = /[.\-_]html\z/.freeze

    def html_key?(full_key)
      !!(full_key =~ HTML_KEY_PATTERN)
    end
  end
end
