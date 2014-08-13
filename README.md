# i18n-tasks [![Build Status][badge-travis]][travis] [![Coverage Status][badge-coverage]][coverage] [![Code Climate][badge-code-climate]][code-climate] [![Gemnasium][badge-gemnasium]][gemnasium]

i18n-tasks helps you find and manage missing and unused translations.

## What?

i18n-tasks scans calls such as `I18n.t('some.key')` and provides reports on key usage, missing, and unused keys.
i18n-tasks can also can pre-fill missing keys, including from Google Translate, and it can remove unused keys as well.

## Why?

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
gem 'i18n-tasks', '~> 0.7.3'
```

Copy default [configuration file](#configuration) (optional):

```console
$ cp $(i18n-tasks gem-path)/templates/config/i18n-tasks.yml config/
```

Copy rspec test to test for missing and unused translations as part of the suite (optional):

```console
$ cp $(i18n-tasks gem-path)/templates/rspec/i18n_spec.rb spec/
```

## Usage

Run `i18n-tasks` to get the list of all the tasks with short descriptions.

### Check health

`i18n-tasks health` checks if any keys are missing or not used:

```console
$ i18n-tasks health
```

### Add missing keys

Add missing keys with placeholders (base value or humanized key):

```console
$ i18n-tasks add-missing
```

This and other tasks accept arguments:

```console
$ i18n-tasks add-missing -v 'TRME %{value}' fr
```

Pass `--help` for more information:

```console
$ i18n-tasks add-missing --help
Usage: i18n-tasks add-missing [options] [locale ...]
    -l, --locales  Comma-separated list of locale(s) to process. Default: all. Special: base.
    -f, --format   Output format: terminal-table, yaml, json, keys, inspect. Default: terminal-table.
    -v, --value    Value. Interpolates: %{value}, %{human_key}, %{value_or_human_key}. Default: %{value_or_human_key}.
    -h, --help     Display this help message.
```

### Google Translate missing keys

Translate missing values with Google Translate ([more below on the API key](#translation-config)).

```console
$ i18n-tasks translate-missing
# accepts from and locales options:
$ i18n-tasks translate-missing --from base es fr
```

### Find usages

See where the keys are used with `i18n-tasks find`:

```bash
$ i18n-tasks find common.help
$ i18n-tasks find 'auth.*'
$ i18n-tasks find '{number,currency}.format.*'
```

<img width="437" height="129" src="https://raw.github.com/glebm/i18n-tasks/master/doc/img/i18n-usages.png">

### Remove unused keys

```bash
$ i18n-tasks unused
$ i18n-tasks remove-unused
```

These tasks will infer [dynamic keys](#dynamic-keys) such as `t("category.\#{category.name}")` by default.
Pass `-s` or `--strict` to disable this feature.

### Normalize data

Sort the keys:

```console
$ i18n-tasks normalize
```

Sort the keys, and move them to the respective files as defined by (`config.write`)[#multiple-locale-files]:

```console
$ i18n-tasks normalize -p
```

### Compose tasks

`i18n-tasks` also provides composable tasks for reading, writing and manipulating locale data.

For example, `add-missing` implemented with `missing`, `tree-set-value` and `data-merge`:

```console
$ i18n-tasks missing -fyaml fr | i18n-tasks tree-set-value 'TRME %{value}' | i18n-tasks data-merge
```

Another example, `remove-unused` implemented with `unused` and `data-remove`:

```bash
$ i18n-tasks unused -fyaml | i18n-tasks data-remove
```

See the full list of tasks with `i18n-tasks --help`.

### Features and limitations

#### Relative keys

`i18n-tasks` offers partial support for relative keys, such as `t '.title'`.

✔ Keys relative to the file path they are used in (see [relative roots configuration](#usage-search)) are supported.

✘ Keys relative to `controller.action_name` in Rails controllers are not supported.

#### Plural keys

✔ Plural keys, such as `key.{one,many,other,...}` are fully supported.

#### `t()` keyword arguments

✔ `scope` keyword argument is supported, but only when it is the first argument.

✘ `default` and other arguments are not supported.

Parsing keyword arguments correctly with Regexp is difficult. This can be improved with an s-expression parser.

#### Dynamic keys

By default, unused report will detect some dynamic keys and not report them, e.g.:

```ruby
t 'category.' + category.key      # all 'category.:' keys considered used (: denotes one key segment)
t "category.#{category.key}.name" # all 'category.:.name' keys considered used
```

This will not be on by default in future versions, in favour of encouraging explicit [i18n-tasks-use hints](#fine-tuning).
For now, you can disable dynamic key inference by passing `-s` or `--strict` to `unused` tasks.

## Configuration

Configuration is read from `config/i18n-tasks.yml` or `config/i18n-tasks.yml.erb`.
Inspect configuration with `i18n-tasks config`.

Install the default config file with:

```console
$ cp $(i18n-tasks gem-path)/templates/config/i18n-tasks.yml config/
```

Settings are compatible with Rails by default.

### Locales

By default, `base_locale` is set to `en` and `locales` are inferred from the paths to data files.
You can override these in the config:

```yaml
# config/i18n-tasks.yml
base_locale: en
locales: [es, fr] # This includes base_locale by default
```

`internal_locale` controls the language i18n-tasks reports in. Locales available are `en` and `ru` (pull request to add more!).

```yaml
internal_locale: en
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

Where this key is depends on your Google API console:

* Old console: API Access -> Simple API Access -> Key for server apps.
* New console: Project -> APIS & AUTH -> Credentials -> Public API access -> Key for server applications.

In both cases, you may need to create the key if it doesn't exist.

Put the key in `GOOGLE_TRANSLATE_API_KEY` environment variable or in the config file.

```yaml
# config/i18n-tasks.yml
translation:
  api_key: <Google Translate API key>
```

## Interactive Console

`i18n-tasks irb` starts an IRB session in i18n-tasks context. Type `guide` for more information.

### XLSX

Export missing and unused data to XLSX:

```console
$ i18n-tasks xlsx-report
```

### HTML

While i18n-tasks does not provide an HTML version of the report, you can add [one like this](https://gist.github.com/glebm/bdd3ab6d12d915f0c81b).


## Add New Tasks

Tasks that come with the gem are defined in [lib/i18n/tasks/command/commands](lib/i18n/tasks/command/commands).

Add a custom task like the ones defined by the gem:

```ruby
# my_commands.rb
class MyCommands
  include ::I18n::Tasks::Command::Collection
  cmd :my_task, desc: 'my custom task'
  def my_task(opts = {})
  end
end
```

```yaml
# config/i18n-tasks.yml
<%
  require 'my_commands'
  I18n::Tasks::Commands.send :include, MyCommands
%>
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
