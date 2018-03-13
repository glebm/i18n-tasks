# frozen_string_literal: true

# Stolen from https://github.com/sickill/rainbow/pull/54
def strip_ansi_escape(string)
  string.gsub(/\e\[[0-9;]*[a-zA-Z]/, '')
end
