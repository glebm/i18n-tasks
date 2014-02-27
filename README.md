# i18n-tasks [![Build Status](https://travis-ci.org/glebm/i18n-tasks.png?branch=master)](https://travis-ci.org/glebm/i18n-tasks) [![Coverage Status](https://coveralls.io/repos/glebm/i18n-tasks/badge.png?branch=master)](https://coveralls.io/r/glebm/i18n-tasks?branch=master) [![Code Climate](https://codeclimate.com/github/glebm/i18n-tasks.png)](https://codeclimate.com/github/glebm/i18n-tasks)


Tasks to manage translations in ruby applications using I18n.

![i18n-screenshot](https://raw.github.com/glebm/i18n-tasks/master/doc/img/i18n-tasks.gif "i18n-tasks output screenshot")

## Installation

1. Add to Gemfile:

  ```ruby
  gem 'i18n-tasks', '~> 0.3.0'
  ```

2. Create a config file at `config/i18n-tasks.yml`:

  ```yaml
  # config/i18n-tasks.yml
  base_locale: en
  locales: [es, fr]
  ```

## Usage

Run `i18n-tasks` to get the list of tasks with short descriptions.

```bash
$ i18n-tasks
Usage: i18n-tasks [command] [options]
    -v, --version      Print the version
    -h, --help         Display this help message.

Available commands:

  missing             show missing translations
  unused              show unused translations
  translate-missing   translate missing keys with Google Translate
  add-missing         add missing keys to the locales
  find                show where the keys are used in the code
  normalize           normalize translation data: sort and move to the right files
  remove-unused       remove unused keys
  config              display i18n-tasks configuration
  xlsx-report         save missing and unused translations to an Excel file

See `<command> --help` for more information on a specific command.
```

There are reports for `missing` and `unused` translations:

```bash
i18n-tasks missing
i18n-tasks unused
```

Add missing values, generated from the key (for base locale) or copied from the base locale (for other locales).

To add missing values to the base locale only:

```bash
# locales argument always accepts `base` and `all` as special values
i18n-tasks add-missing -l base
```

Translate missing values with Google Translate ([more below on the API key](#translation-config)).

```bash
i18n-tasks translate-missing
# accepts from and locales options:
i18n-tasks translate-missing -f base -l es,fr
```

Sort the keys and write them to their respective files with `normalize`.
This always happens on `add-missing` and `translate-missing`.

```bash
i18n-tasks normalize
```

See exactly where the keys are used with `find`:

```bash
# Show all usages of all keys
i18n-tasks find
# Filter by a key pattern
i18n-tasks find 'auth.*'
i18n-tasks find '{number,currency}.format.*'
```

![i18n-screenshot](https://raw.github.com/glebm/i18n-tasks/master/doc/img/i18n-usages.png "i18n-tasks find output screenshot")

Relative keys (`t '.title'`) and plural keys (key.one/many/other/etc) are fully supported.

Scope argument is supported, but only when it is the first keyword argument ([this](/lib/i18n/tasks/scanners/pattern_with_scope_scanner.rb) can be improved):

```ruby
# this is supported
t :invalid, scope: [:auth, :password], attempts: 5
# but not this
t :invalid, attempts: 5, scope: [:auth, :password]
```

Unused report will detect pattern translations and not report them, e.g.:

```ruby
t 'category.' + category.key      # all 'category.*' keys are considered used
t "category.#{category.key}.name" # all 'category.*.name' keys are considered used
```

Translation data storage, key usage search, and other [settings](#configuration) are compatible with Rails by default.

## Configuration

Configuration is read from `config/i18n-tasks.yml` or `config/i18n-tasks.yml.erb`.
Inspect configuration with `i18n-tasks config`.

### Locales

By default, i18n-tasks will read `I18n.default_locale` and `I18n.available_locales`.
However, i18n-tasks does not load application environment by default,
so it is recommended to set locale settings explicitly:

```yaml
# config/i18n-tasks.yml
base_locale: en
locales: [es, fr]
```

### Storage

The default data adapter supports YAML and JSON files.

```yaml
# i18n data storage
data:
  # file_system is the default adapter, you can provide a custom class name here:
  adapter: file_system
  # a list of file globs to read from per-locale
  read: 
    # default:
    - 'config/locales/%{locale}.yml'
    # to also read from namespaced files, e.g. simple_form.en.yml:
    - 'config/locales/*.%{locale}.yml'
  # a list of {key pattern => file} routes, matched top to bottom
  write:
    # save all devise keys in it's own file (per locale):
    - ['devise.*', 'config/locales/devise.%{locale}.yml']
    # default catch-all:
    - 'config/locales/%{locale}.yml' # path is short for ['*', path]
```

#### Key pattern syntax

| syntax       | description                                               |
|:------------:|:----------------------------------------------------------|
|      `*`     | matches everything                                        |
|      `:`     | matches a single key                                      |
|   `{a, b.c}` | match any in set, can use `:` and `*`, match is captured  |

Example:

```yaml
data:
  write:
    # store sorcery and simple_form keys in the respective files:
    - ['{sorcery,simple_form}.*', 'config/locales/\1.%{locale}.yml']
    # write every key namespace to its own file:
    - ['{:}.*', 'config/locales/\1.%{locale}.yml']
```

### Usage search


Configure usage search in `config/i18n-tasks.yml`:

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

To configure paths for relative key resolution:

```yaml
# directories containing relative keys
relative_roots:
  # default:
  - app/views
  # add a custom one:
  - app/views-mobile
```

It is also possible to use a custom key usage scanner by setting `search.scanner` to a class name.
See this basic [pattern scanner](/lib/i18n/tasks/scanners/pattern_scanner.rb) for reference.


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
  # E.g to ignore all Rails number / currency keys:
  - 'number.{format, percentage.format, precision.format, human.format, currency.format}.{strip_insignificant_zeros,significant,delimiter}'
  - 'time.{pm,am}'

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

<a name="translation-config"></a>
### Google Translate

`i18n-tasks translate-missing` requires a Google Translate API key, get it at [Google API Console](https://code.google.com/apis/console).
Put the key in `GOOGLE_TRANSLATE_API_KEY` environment variable or in the config file.

```yaml
translation:
  api_key: <Google Translate API key>
```

## RSpec integration

You might want to test for missing and unused translations as part of your test suite.
This is how you can do it with rspec:

```ruby
# spec/i18n_keys_spec.rb:
require 'spec_helper'

require 'i18n/tasks'

describe 'Translation keys'  do
  let(:i18n) { I18n::Tasks::BaseTask.new }

  it 'are all present' do
    expect(i18n.missing_keys).to have(0).keys
  end

  it 'are all used' do
    expect(i18n.unused_keys).to have(0).keys
  end
end

```

## XLSX

Export missing and unused data to XLSX:

```bash
i18n-tasks xlsx-report
```


## HTML

While i18n-tasks does not provide an HTML version of the report, you can add [one like this](https://gist.github.com/glebm/6887030).

---

This was originally developed for [Zuigo](http://zuigo.com/), a platform to organize and discover events.

[MIT license](/LICENSE.txt)
