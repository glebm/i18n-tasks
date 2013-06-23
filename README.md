i18n-tasks
==========

I18n tasks to find missing / unused translations and more

There are 3 tasks available to manage translations.

    $ rake -T i18n
    rake i18n:missing  # show keys with translation values identical to base
    rake i18n:prefill  # add keys from base locale to others
    rake i18n:unused   # find potentially unused translations

* `i18n:missing` task shows all the keys that have not been translated yet
* `i18n:prefill` task adds missing keys to locale files, prefilling with base locale (en) value by default

* `i18n:unused` task shows potentially unused translations

`i18n:unused` will detect pattern translations and not report them, e.g.:

    t 'category.' + category.key # category.* translations will be considered used
    t "category.#{category.key}" # also works

Installation
============

Simply add to Gemfile:

    gem 'i18n-tasks', '~> 0.0.1'
