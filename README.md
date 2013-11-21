# i18n-tasks [![Build Status](https://travis-ci.org/glebm/i18n-tasks.png?branch=master)](https://travis-ci.org/glebm/i18n-tasks) [![Code Climate](https://codeclimate.com/github/glebm/i18n-tasks.png)](https://codeclimate.com/github/glebm/i18n-tasks)


Rails I18n tasks to find missing / unused translations and more. Works with slim / coffee / haml etc.

![i18n-screenshot](https://raw.github.com/glebm/i18n-tasks/master/doc/img/i18n-tasks.png "i18n-tasks output screenshot")

## Usage

Use `rake -T i18n` to get the list of tasks with descriptions. There are 3 tasks available at the moment:

* `i18n:missing` task shows all the keys that have not been translated yet *([source](/lib/i18n/tasks/missing.rb))*
* `i18n:unused` task shows potentially unused translations *([source](/lib/i18n/tasks/unused.rb))*
* `i18n:prefill` task normalizes locale files, and adds missing keys from base locale to others *([source](/lib/i18n/tasks/prefill.rb))*


The `i18n:unused` task will detect pattern translations and not report them, e.g.:

```ruby
t 'category.' + category.key # 'category.arts_and_crafts' considered used
t "category.#{category.key}" # also works
```

Relative keys (`t '.title'`) and plural keys (key.one/many/other/etc) are fully supported.

For more examples see [the tests](/spec/i18n_tasks_spec.rb).


## Installation

Simply add to Gemfile:

```ruby
gem 'i18n-tasks', '~> 0.1.7'
```

## Configuration

Configuration is read from `config/i18n-tasks.yml`.

### Storage

```yaml
# i18n data storage
data:
  # The default YAML adapter supports reading from and writing to YAML files
  adapter: yaml
  # yaml adapter read option is a list of glob patterns of files to read from per-locale
  read: 
    # this one is default:
    - 'config/locales/%{locale}.yml'
    # this one would add some more files:
    - 'config/locales/*.%{locale}.yml'
  # yaml adapter write option a list of key pattern => output filename "routes" per-locale
  write:
    # keys matched top to bottom
    - ['devise.*', 'config/locales/devise.%{locale}.yml']
    # default catch-all (same as ['*', 'config/locales/%{locale}.yml'])
    - 'config/locales/%{locale}.yml'
```

### Usage search

```yaml
# i18n usage search in source
search:
  # search these directories (relative to your Rails.root directory, default: 'app/')
  paths:
    - 'app/'
    - 'vendor/'
  # include only files matching this glob pattern (default: blank = include all files)
  include:
    - '*.rb'
    - '*.html.*'
    - '*.text.*'
  # explicitly exclude files (default: blank = exclude no files)
  exclude:
    - '*.js'
  # you can override the default grep pattern:
  pattern: "\\bt[( ]\\s*(.)((?<=\").+?(?=\")|(?<=').+?(?=')|(?<=:)\\w+\\b)"
```

### Fine-tuning

Tasks may incorrectly report framework i18n keys as missing, also some patterns may not be detected.
When all else fails, use the options below.

```yaml
# do not report these keys as unused
ignore_unused:
  - category.*.db_name

# do not report these keys as missing (both on blank value and no key)
ignore_missing:
  - devise.errors.unauthorized # ignore this key
  - pagination.views.*         # ignore the whole pattern

# do not report these keys when they have the same value as the base locale version
ignore_eq_base:
  all:
    - common.ok
  es,fr:
    - common.brand

# do not report these keys ever
ignore:
  - kaminari.*
```

## HTML report

While i18n-tasks does not provide an HTML version of the report, it's easy to roll your own, see [the example](https://gist.github.com/glebm/6887030).

---

This was originally developed for [Zuigo](http://zuigo.com/), a platform to organize and discover events.

[MIT license](/LICENSE.txt)


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/glebm/i18n-tasks/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

