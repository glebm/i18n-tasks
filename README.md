# i18n-tasks [![Build Status](https://travis-ci.org/glebm/i18n-tasks.png?branch=master)](https://travis-ci.org/glebm/i18n-tasks) [![Code Climate](https://codeclimate.com/github/glebm/i18n-tasks.png)](https://codeclimate.com/github/glebm/i18n-tasks)


Tasks to manage missing and unused translations in Rails.

![i18n-screenshot](https://raw.github.com/glebm/i18n-tasks/master/doc/img/i18n-tasks.gif "i18n-tasks output screenshot")

## Usage

Use `rake -T i18n` to get the list of tasks with descriptions. These are [the tasks](/lib/tasks/i18n-tasks.rake) available:

There are reports for missing and unused translations:
```bash
rake i18n:missing
rake i18n:unused
# or save both to an xlsx file:
rake i18n:spreadsheet_report
```

To add the keys that are not in the base locale data but detected in the source do:
```bash
# add missing keys to the base locale data (I18n.default_locale)
# values set to key.humanize
rake i18n:add_missing
# or set all values to the task argument
rake i18n:add_missing[OhNoesMissing]
```

Prefill empty translations using Google Translate:
```bash
rake i18n:fill:google_translate
# this task and the ones below can also accept specific locales:
rake i18n:fill:google_translate[es+de]
```
Prefill using values from the base locale - `I8n.default_locale`:
```bash
rake i18n:fill:base_value
```
Add just blank yaml keys - `key: ''` for all missing and untranslated keys:
```bash
rake i18n:fill:blanks
```

i18n-tasks sorts the keys and writes them to their respective files:
```bash
# this happens automatically on any i18n:fill:* task
rake i18n:normalize 
```


`i18n:unused` will detect pattern translations and not report them, e.g.:

```ruby
t 'category.' + category.key # 'category.arts_and_crafts' considered used
t "category.#{category.key}" # also works
```

Relative keys (`t '.title'`) and plural keys (key.one/many/other/etc) are fully supported.

For more examples see [the tests](/spec/i18n_tasks_spec.rb).


## Installation

Simply add to Gemfile:

```ruby
gem 'i18n-tasks', '~> 0.2.2'
```

## Configuration

Configuration is read from `config/i18n-tasks.yml`.

### Storage

```yaml
# i18n data storage
data:
  # The default YAML adapter supports reading from and writing to YAML files
  adapter: yaml
  # a list of file globs to read from per-locale
  read: 
    # this one is default:
    - 'config/locales/%{locale}.yml'
    # add this one to also read from namespaced files, e.g. simple_form.en.yml:
    - 'config/locales/*.%{locale}.yml'
  # a list of {key => file} routes per-locale
  write:
    # this would route all devise namespaced keys:
    - ['devise.*', 'config/locales/devise.%{locale}.yml']
    # this is the default catch-all. this is a shortcut for ['*', 'config/locales/%{locale}.yml']
    - 'config/locales/%{locale}.yml'
```

### Translation

Set `GOOGLE_TRANSLATE_API_KEY` environment variable, or specify the key in config/i18n-tasks.yml:

```yaml
translation:
  api_key: THE_KEY
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
  # you can override the default key regex pattern:
  pattern: "\\bt[( ]\\s*(:?\".+?\"|:?'.+?'|:\\w+)"
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

