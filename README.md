# i18n-tasks [![Build Status](https://travis-ci.org/glebm/i18n-tasks.png?branch=master)](https://travis-ci.org/glebm/i18n-tasks) [![Code Climate](https://codeclimate.com/github/glebm/i18n-tasks.png)](https://codeclimate.com/github/glebm/i18n-tasks)


Rails I18n tasks to find missing / unused translations and more. Works with slim / coffee / haml etc.

![i18n-missing-screenshot](https://raw.github.com/glebm/i18n-tasks/master/doc/img/i18n-tasks.png "rake i18n:missing output screenshot")

Use `rake -T i18n` to get the list of tasks with descriptions. There are 3 tasks available at the moment:

* `i18n:missing` task shows all the keys that have not been translated yet *([source](./blob/master/lib/i18n/tasks/missing.rb))*
* `i18n:prefill` task normalizes locale files, and adds missing keys from base locale to others *([source](./blob/master/lib/i18n/tasks/prefill.rb))*
* `i18n:unused` task shows potentially unused translations *([source](./blob/master/lib/i18n/tasks/unused.rb))*

The `i18n:unused` task will detect pattern translations and not report them, e.g.:

```ruby
t 'category.' + category.key # 'category.arts_and_crafts' considered used
t "category.#{category.key}" # also works
```

Relative keys (`t '.title'`) are supported. Plural keys (key.one/many/other/etc) are supported.

For more examples see [the tests](./blob/master/spec/i18n_tasks_spec.rb#L43-L59).


## Installation

Simply add to Gemfile:

```ruby
gem 'i18n-tasks', '~> 0.1.0'
```

`grep` is required. You likely have it already on Linux / Mac / BSD, Windows users will need to [install](http://gnuwin32.sourceforge.net/packages/grep.htm) and make sure it's available in `PATH`.


## Configuration

Tasks may incorrectly report framework i18n keys as missing. You can add `config/i18n-tasks.yml` to work around this:

```yaml
# do not report these keys as missing (both on blank value and no key)
ignore_missing:
  - devise.errors.unauthorized # ignore this key
  - pagination.views.          # ignore the whole pattern (note the .)

# do not report these keys when they have the same value as the base locale version
ignore_eq_base:
  all:
    - common.ok
  es,fr:
    - common.brand

# do not report these keys as unused
ignore_unused:
  - category.

# do not report these keys ever
ignore:
  - kaminari.

# grep configuration
grep:
  # search these directories (relative to your Rails.root directory, default: 'app/')
  paths:
    - 'app/'
    - 'vendor/'
  # include only files matching this glob pattern (default: blank = include all files)
  include:
    - '*.rb'
    - '*.html*'
  # explicitly exclude files (default: blank = exclude no files)
  exclude: '*.js'
```


By default reports I18n reads locale data from `config/locales/{locale_code}.yml`.
You can customize this, e.g.:

```ruby
# load all config/locales/*.locale.yml and config/locales/locale.yml:
I18n::Tasks.get_locale_data = ->(locale) {
  (["config/locales/#{locale}.yml"] + Dir["config/locales/*.#{locale}.yml"]).inject({}) { |hash, path|
    hash.deep_merge! YAML.load_file(path)
    hash
  }
}
```

## i18n-tasks HTML report

While i18n-tasks does not provide an HTML version of the report, it's easy to roll your own, see [the example](https://gist.github.com/glebm/6887030).

---

This was originally developed for [Zuigo](http://zuigo.com/), a platform to organize and discover events.

