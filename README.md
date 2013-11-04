# i18n-tasks [![Build Status](https://travis-ci.org/glebm/i18n-tasks.png?branch=master)](https://travis-ci.org/glebm/i18n-tasks) [![Code Climate](https://codeclimate.com/github/glebm/i18n-tasks.png)](https://codeclimate.com/github/glebm/i18n-tasks)


Rails I18n tasks to find missing / unused translations and more. Works with slim / coffee / haml etc.

![i18n-missing-screenshot](https://raw.github.com/glebm/i18n-tasks/master/doc/img/i18n-tasks.png "rake i18n:missing output screenshot")

Use `rake -T i18n` to get the list of tasks with descriptions. There are 3 tasks available at the moment:

* `i18n:missing` task shows all the keys that have not been translated yet *([source](/lib/i18n/tasks/missing.rb))*
* `i18n:prefill` task normalizes locale files, and adds missing keys from base locale to others *([source](/lib/i18n/tasks/prefill.rb))*
* `i18n:unused` task shows potentially unused translations *([source](/lib/i18n/tasks/unused.rb))*

The `i18n:unused` task will detect pattern translations and not report them, e.g.:

```ruby
t 'category.' + category.key # 'category.arts_and_crafts' considered used
t "category.#{category.key}" # also works
```

Relative keys (`t '.title'`) are supported. Plural keys (key.one/many/other/etc) are supported.

For more examples see [the tests](/spec/i18n_tasks_spec.rb).


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

# search configuration (grep arguments)
grep:
  # search these directories (relative to your Rails.root directory, default: 'app/')
  paths:
    - 'app/'
  # include only files matching this glob pattern (default: blank = include all files)
  include:
    - '*.rb'
    - '*.html*'
  # explicitly exclude files (default: blank = exclude no files)
  exclude: '*.js'

# where to get locale data (defaults below)
data:
  # files for a given %{locale}
  paths:
    - 'config/locales/%{locale}.yml'
    - 'config/locales/*.%{locale}.yml'
  # you can also override the loading mechanism
  class: I18n::Tasks::Data::Yaml

## i18n-tasks HTML report

While i18n-tasks does not provide an HTML version of the report, it's easy to roll your own, see [the example](https://gist.github.com/glebm/6887030).

---

This was originally developed for [Zuigo](http://zuigo.com/), a platform to organize and discover events.



[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/glebm/i18n-tasks/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

