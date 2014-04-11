# i18n-tasks [![Build Status][badge-travis]][travis] [![Coverage Status][badge-coveralls]][coveralls] [![Code Climate][badge-code-climate]][code-climate] [![Gemnasium][badge-gemnasium]][gemnasium]

i18n-tasks finds and manages missing and unused translations in your application.

The default approach to locale data management with gems such as [i18n][i18n-gem] is flawed.
If you use a key that does not exist, this will only blow up at runtime. Keys left over from removed code accumulate
in the resource files and introduce unnecessary overhead on the translators. Translation files can quickly turn to disarray.

i18n-tasks improves this by using static analysis. It scans calls such as `I18n.t('some.key')` and provides reports on key usage, missing, and unused keys.
It can also pre-fill missing keys, including from Google Translate, and it can remove unused keys as well.

i18n-tasks can be used with any project using [i18n][i18n-gem] (default in Rails), or similar, even if it isn't ruby.

<img width="534" height="288" src="https://raw.github.com/glebm/i18n-tasks/master/doc/img/i18n-tasks.png">

## Installation

Add to Gemfile:

```ruby
gem 'i18n-tasks', '~> 0.3.9'
```

i18n-tasks does not load or execute any of the application's code but performs static-only analysic.
This means you can install the gem and run it on a project without adding it to Gemfile.

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

You can add missing values, generated from the key (for base locale) or copied from the base locale (for other locales).
To add missing values to the base locale only:

```bash
# most task accept locales as first argument. `base` and `all` are special
i18n-tasks add-missing base
```

Translate missing values with Google Translate ([more below on the API key](#translation-config)).

```bash
i18n-tasks translate-missing
# accepts from and locales options:
i18n-tasks translate-missing --from base es fr
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

![i18n-screenshot][screenshot-find]

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

By default, `base_locale` is set to `en` and `locales` are inferred from the paths to data files.
You can override these in the config:

```yaml
# config/i18n-tasks.yml
base_locale: en
locales: [es, fr] # This includes base_locale by default
```

### Storage

The default data adapter supports YAML and JSON files.

```yaml
# config/i18n-tasks.yml
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
# config/i18n-tasks.yml
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
# config/i18n-tasks.yml
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
# config/i18n-tasks.yml
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
# config/i18n-tasks.yml
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
# config/i18n-tasks.yml
translation:
  api_key: <Google Translate API key>
```

## RSpec integration

You might want to test for missing and unused translations as part of your test suite.
This is how you can do it with rspec:

```ruby
# spec/i18n_spec.rb:
require 'spec_helper'
require 'i18n/tasks'

describe 'I18n' do
  before :all { @i18n = I18n::Tasks::BaseTask.new }

  it "doesn't have any missing keys" do
    count = @i18n.missing_keys.count
    fail "There are #{count} missing i18n keys! Run 'i18n-tasks missing' for more details." if count > 0
  end

  it "doesn't have any unused keys" do
    count = @i18n.unused_keys.count
    fail "There are #{count} unused i18n keys! Run 'i18n-tasks unused' for more details." if count > 0
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

[MIT license]: /LICENSE.txt
[travis]: https://travis-ci.org/glebm/i18n-tasks
[badge-travis]: http://img.shields.io/travis/glebm/i18n-tasks.svg
[coveralls]: https://coveralls.io/r/glebm/i18n-tasks?branch=master
[badge-coveralls]: http://img.shields.io/coveralls/glebm/i18n-tasks.svg
[gemnasium]: https://gemnasium.com/glebm/i18n-tasks
[badge-gemnasium]: https://gemnasium.com/glebm/i18n-tasks.svg
[code-climate]: https://codeclimate.com/github/glebm/i18n-tasks
[badge-code-climate]: http://img.shields.io/codeclimate/github/glebm/i18n-tasks.svg
[i18n-gem]: https://github.com/svenfuchs/i18n "svenfuchs/i18n on Github"
[screenshot-find]: https://raw.github.com/glebm/i18n-tasks/master/doc/img/i18n-usages.png "i18n-tasks find output screenshot"
