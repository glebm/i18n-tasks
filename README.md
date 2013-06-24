i18n-tasks  [![Build Status](https://travis-ci.org/glebm/i18n-tasks.png?branch=master)](https://travis-ci.org/glebm/i18n-tasks)
==========

I18n tasks to find missing / unused translations and more. Works with slim / coffee / haml etc.

There are 3 tasks available to manage translations.

`rake -T i18n`:
* `i18n:missing` task shows all the keys that have not been translated yet
* `i18n:prefill` task normalizes locale files, and adds missing keys from base locale to others
* `i18n:unused` task shows potentially unused translations

`i18n:unused` will detect pattern translations and not report them, e.g.:

    t 'category.' + category.key # 'category.arts_and_crafts' considered used
    t "category.#{category.key}" # also works

Installation
============

Simply add to Gemfile:

    gem 'i18n-tasks', '~> 0.0.1'
