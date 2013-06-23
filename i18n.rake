require 'set'
require 'open3'

namespace :i18n do
  desc 'add keys from base locale to others'
  task :prefill => :environment do
    # Will also rewrite en, good for ordering
    I18n.available_locales.map(&:to_s).each do |target_locale|
      trn = YAML.load_file trn_path(target_locale)
      prefilled = { target_locale => base[base_locale] }.deep_merge(trn)
      File.open(trn_path(target_locale), 'w'){ |f| f.write prefilled.to_yaml }
    end
  end

  desc 'show keys with translation values identical to base'
  task :missing => :environment do
    (I18n.available_locales.map(&:to_s) - [base_locale]).each do |locale|
      trn = YAML.load_file(trn_path(locale))[locale]
      traverse base[base_locale] do |key, base_value|
        translated = t(trn, key)
        if translated.blank? || translated == base_value
          puts "#{locale}.#{key}: #{base_value}"
        end
      end
    end
  end

  desc 'find potentially unused translations'
  task :unused => :environment do
    _in, out, _err = Open3.popen3 'grep', '-horI', %q{\\bt(\\?\\s*['"]\\([^'"]*\\)['"]}, 'app/'
    used_keys = out.gets(nil).split("\n").map { |r| r.match(/['"](.*?)['"]/)[1] }.uniq.to_set
    pattern_prefixes = used_keys.select { |key| key =~ /\#{.*?}/ || key.ends_with?('.') }.map { |key| key.split(/\.?#/)[0] }
    traverse base[base_locale] do |key, value|
      if !used_keys.include?(key) && !pattern_prefixes.any? { |pp| key.start_with?(pp) }
        puts "#{key}: #{value}"
      end
    end
  end

  define_method :trn_path do |locale|
    "config/locales/#{locale}.yml"
  end

  define_method :traverse do |path = '', hash, &block|
    hash.each do |k, v|
      if v.is_a?(Hash)
        traverse("#{path}.#{k}", v, &block)
      else
        block.call("#{path}.#{k}"[1..-1], v)
      end
    end
  end

  define_method :t do |hash, key|
    key.split('.').inject(hash) { |r, seg| r.try(:[], seg) }
  end

  define_method :base_locale do
    I18n.default_locale.to_s
  end

  define_method :base do
    @base ||= YAML.load_file trn_path(base_locale)
  end
end
