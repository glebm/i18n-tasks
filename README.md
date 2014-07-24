# i18n-tasks [![Build Status][badge-travis]][travis] [![Coverage Status][badge-coverage]][coverage] [![Code Climate][badge-code-climate]][code-climate] [![Gemnasium][badge-gemnasium]][gemnasium]

i18n-tasks helps you find and manage missing and unused translations.

The default approach to locale data management with gems such as [i18n][i18n-gem] is flawed.
If you use a key that does not exist, this will only blow up at runtime. Keys left over from removed code accumulate
in the resource files and introduce unnecessary overhead on the translators. Translation files can quickly turn to disarray.

i18n-tasks improves this by analysing code statically, without running it. It scans calls such as `I18n.t('some.key')` and provides reports on key usage, missing, and unused keys.
It can also pre-fill missing keys, including from Google Translate, and it can remove unused keys as well.

i18n-tasks can be used with any project using [i18n][i18n-gem] (default in Rails), or similar, even if it isn't ruby.

<img width="539" height="331" src="https://raw.github.com/glebm/i18n-tasks/master/doc/img/i18n-tasks.png">

## Installation

Add to Gemfile:

```ruby
gem 'i18n-tasks', '~> 0.6.3'
```

Copy default [config file](#configuration) (optional):

```console
$ cp $(i18n-tasks gem-path)/templates/config/i18n-tasks.yml config/
```

Copy [rspec test](#rspec-integration) (optional):

```console
$ cp $(i18n-tasks gem-path)/templates/rspec/i18n_spec.rb spec/
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
  eq-base             show translations equal to base value
  find                show where the keys are used in the code
  data                show locale data
  translate-missing   translate missing keys with Google Translate
  add-missing         add missing keys to the locales
  normalize           normalize translation data: sort and move to the right files
  remove-unused       remove unused keys
  config              display i18n-tasks configuration
  xlsx-report         save missing and unused translations to an Excel file
  irb                 REPL session within i18n-tasks context
  gem-path            show path to the gem

See `<command> --help` for more information on a specific command.
```

Show tasks accept a format option, and all but `find` accept locales as arguments, e.g:

```bash
$ i18n-tasks data --help
Usage: i18n-tasks data [options]
    -l, --locales      Filter by locale(s), comma-separated list (en,fr) or all (default), or pass arguments without -l
    -f, --format       Output format: terminal-table, yaml, json, keys, inspect. Default: terminal-table.
    -h, --help         Display this help message.
$ i18n-tasks data -fkeys en es fr
```

#### Add missing keys

You can add missing values, generated from the key (for base locale) or copied from the base locale (for other locales).
To add missing values to the base locale only:

```bash
# most task accept locales as first argument. `base` and `all` are special
i18n-tasks add-missing base
# add-missing accepts a placeholder argument, with optional base_value interpolation
i18n-tasks add-missing -p 'PLEASE-TRANSLATE %{base_value}' fr
```

#### Google Translate missing keys

Translate missing values with Google Translate ([more below on the API key](#translation-config)).

```bash
i18n-tasks translate-missing
# accepts from and locales options:
i18n-tasks translate-missing --from base es fr
```

Sort the keys and write them to their respective files with `i18n-tasks normalize`.
This always happens on `i18n-tasks add-missing` and `i18n-tasks translate-missing`.

```bash
i18n-tasks normalize
```

#### Find usages

See where the keys are used with `i18n-tasks find`:

```bash
i18n-tasks find common.help
i18n-tasks find 'auth.*'
i18n-tasks find '{number,currency}.format.*'
```

![i18n-screenshot][screenshot-find]

### Find / remove unused keys

```bash
i18n-tasks unused
i18n-tasks remove-unused
```

These tasks will infer dynamic key usage such as `t("category.\#{category.name}")` by default.
Pass `-s` or `--strict` to disable this feature.

#### Features

Relative keys (`t '.title'`) and plural keys (`key.{one,many,other,...}`) are fully supported.
Scope argument is supported, but only when it is the first keyword argument ([improvements welcome](/lib/i18n/tasks/scanners/pattern_with_scope_scanner.rb)):

    ```ruby
    # this is supported
    t :invalid, scope: [:auth, :password], attempts: 5
    # but not this
    t :invalid, attempts: 5, scope: [:auth, :password]
    ```

Unused report will detect certain dynamic key forms and not report them, e.g.:

```ruby
t 'category.' + category.key      # all 'category.*' keys are considered used
t "category.#{category.key}.name" # all 'category.*.name' keys are considered used
```

Translation data storage, key usage search, and other [settings](#configuration) are compatible with Rails by default.

## Configuration

Configuration is read from `config/i18n-tasks.yml` or `config/i18n-tasks.yml.erb`.
Inspect configuration with `i18n-tasks config`.

Install the default config file with:

```console
$ cp $(i18n-tasks gem-path)/templates/config/i18n-tasks.yml config/
```

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
data:
  # configure YAML / JSON serializer options
  # passed directly to load / dump / parse / serialize.
  yaml:
    write:
      # do not wrap lines at 80 characters (override default)
      line_width: -1
```

#### Multiple locale files

Use `data` options to work with locale data spread over multiple files.

`data.read` accepts a list of file globs to read from per-locale:

```
# config/i18n-tasks.yml
data:
  read:
    # read from namespaced files, e.g. simple_form.en.yml
    - 'config/locales/*.%{locale}.yml'
    # read from a gem (config is parsed with ERB first, then YAML)
    - "<%= %x[bundle show vagrant].chomp %>/templates/locales/%{locale}.yml"
    # default
    - 'config/locales/%{locale}.yml'
```

#### Key pattern syntax

| syntax       | description                                               |
|:------------:|:----------------------------------------------------------|
|      `*`     | matches everything                                        |
|      `:`     | matches a single key                                      |
|   `{a, b.c}` | match any in set, can use `:` and `*`, match is captured  |

For writing to locale files i18n-tasks provides 2 options.

##### Pattern router

Pattern router organizes keys based on a list of key patterns, as in the example below:

```
data:
  router: pattern_router
  # a list of {key pattern => file} routes, matched top to bottom
  write:
    # write models.* and views.* keys to the respective files
    - ['{models,views}.*', 'config/locales/\1.%{locale}.yml']
    # or, write every top-level key namespace to its own file
    - ['{:}.*', 'config/locales/\1.%{locale}.yml']
    # default, sugar for ['*', path]
    - 'config/locales/%{locale}.yml'
```

##### Conservative router

Conservative router keeps the keys where they are found, or infers the path from base locale.
If the key is completely new, conservative router will fall back to pattern router behaviour.
Conservative router is the default router.

```
data:
  router: conservative_router
  write:
    - ['devise.*', 'config/locales/devise.%{locale}.yml']
    - 'config/locales/%{locale}.yml'
```

#### Custom adapters

If you store data somewhere but in the filesystem, e.g. in the database or mongodb, you can implement a custom adapter.
Implement [a handful of methods][adapter-example], then set `data.adapter` to the class name; the rest of the `data` config is passed to the initializer.

```yaml
# config/i18n-tasks.yml
data:
  # file_system is the default adapter, you can provide a custom class name here:
  adapter: file_system
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
  # paths for relative key resolution:
  relative_roots:
    # default:
    - app/views
    # add a custom one:
    - app/views-mobile
  # include only files matching this glob pattern (default: blank = include all files)
  include:
    - '*.rb'
    - '*.html.*'
    - '*.text.*'
  # explicitly exclude files (default: exclude common binary files)
  exclude:
    - '*.js'
  # you can override the default key regex pattern:
  pattern: "\\bt[( ]\\s*(:?\".+?\"|:?'.+?'|:\\w+)"
  # comments are ignored by default
  ignore_lines:
    - "^\\s*[#/](?!\\si18n-tasks-use)"
```

It is also possible to use a custom key usage scanner by setting `search.scanner` to a class name.
See this basic [pattern scanner](/lib/i18n/tasks/scanners/pattern_scanner.rb) for reference.


### Fine-tuning

Add hints to static analysis with magic comment hints (lines starting with `(#|/) i18n-tasks-use` by default):

```ruby
# i18n-tasks-use t('activerecord.models.user') # let i18n-tasks know the key is used
User.model_name.human
```

You can also explicitly ignore keys appearing in locale files:

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

## Interactive Console

`i18n-tasks irb` starts an IRB session in i18n-tasks context. Type `guide` for more information.

## RSpec integration

You might want to test for missing and unused translations as part of your test suite.
Install the spec file:

```console
$ cp $(i18n-tasks gem-path)/templates/rspec/i18n_spec.rb spec/
```

### XLSX

Export missing and unused data to XLSX:

```console
$ i18n-tasks xlsx-report
```

### HTML

While i18n-tasks does not provide an HTML version of the report, you can add [one like this](https://gist.github.com/glebm/bdd3ab6d12d915f0c81b).


## Add New Tasks

Tasks that come with the gem are defined in [lib/i18n/tasks/commands.rb](lib/i18n/tasks/commands.rb).

Add a custom task to the [I18n::Tasks::Commands](lib/i18n/tasks/commands.rb) class and load the task in `config/i18n-tasks.yml`:

```ruby
# lib/i18n/tasks/my_task.rb
I18n::Tasks::Commands.class_eval do
  cmd :my_task, desc: 'my task'
  def my_task(opts = {})
    puts i18n.data[opts[:arguments].try(:first) || base_locale]
  end
end
```

```yaml
# config/i18n-tasks.yml
<% require 'i18n/tasks/my_task' %>
```

Run with:

```console
$ i18n-tasks my-task
```

[MIT license]: /LICENSE.txt
[travis]: https://travis-ci.org/glebm/i18n-tasks
[badge-travis]: http://img.shields.io/travis/glebm/i18n-tasks.svg
[coverage]: https://codeclimate.com/github/glebm/i18n-tasks
[badge-coverage]: https://img.shields.io/codeclimate/coverage/github/glebm/i18n-tasks.svg
[gemnasium]: https://gemnasium.com/glebm/i18n-tasks
[badge-gemnasium]: https://gemnasium.com/glebm/i18n-tasks.svg
[code-climate]: https://codeclimate.com/github/glebm/i18n-tasks
[badge-code-climate]: http://img.shields.io/codeclimate/github/glebm/i18n-tasks.svg
[i18n-gem]: https://github.com/svenfuchs/i18n "svenfuchs/i18n on Github"
[screenshot-find]: https://raw.github.com/glebm/i18n-tasks/master/doc/img/i18n-usages.png "i18n-tasks find output screenshot"
[adapter-example]: https://github.com/glebm/i18n-tasks/blob/master/lib/i18n/tasks/data/file_system_base.rb
