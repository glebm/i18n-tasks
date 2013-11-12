module I18n::Tasks::RelativeKeys

  # @param key [String] relative i18n key (starts with a .)
  # @param path [String] path to the file containing the key
  # @return [String] absolute version of the key
  def absolutize_key(key, path)
    # normalized path
    path   = Pathname.new(File.expand_path path).relative_path_from(Pathname.new(Dir.pwd)).to_s
    # key prefix based on path
    prefix = path.gsub(%r(app/views/|(\.[^/]+)*$), '').tr('/', '.').gsub(%r(\._), '.')
    "#{prefix}#{key}"
  end
end