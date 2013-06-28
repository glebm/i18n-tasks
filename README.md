i18n-tasks  [![Build Status](https://travis-ci.org/glebm/i18n-tasks.png?branch=master)](https://travis-ci.org/glebm/i18n-tasks)
==========

Rails I18n tasks to find missing / unused translations and more. Works with slim / coffee / haml etc.

Use `rake -T i18n` to get the list of tasks with descriptions. There are 3 tasks available at the moment:

* `i18n:missing` task shows all the keys that have not been translated yet *([source](https://github.com/glebm/i18n-tasks/blob/master/lib/i18n/tasks/missing.rb))*
* `i18n:prefill` task normalizes locale files, and adds missing keys from base locale to others *([source](https://github.com/glebm/i18n-tasks/blob/master/lib/i18n/tasks/prefill.rb))*
* `i18n:unused` task shows potentially unused translations *([source](https://github.com/glebm/i18n-tasks/blob/master/lib/i18n/tasks/unused.rb))*

`i18n:unused` will detect pattern translations and not report them, e.g.:

    t 'category.' + category.key # 'category.arts_and_crafts' considered used
    t "category.#{category.key}" # also works

For more examples see [the tests](https://github.com/glebm/i18n-tasks/blob/master/spec/i18n_tasks_spec.rb#L43-L59).

Installation
------------

Simply add to Gemfile:

    gem 'i18n-tasks', '~> 0.0.3'

Configuration
-------------

Currently i18n-tasks only reports / writes to locale data in `config/locales/{locale_code}.yml`. *PRs making this configurable welcome!*
