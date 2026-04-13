# i18n-tasks [![Build Status][badge-ci]][ci] [![Coverage Status][badge-coverage]][coverage] [![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/glebm/i18n-tasks?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![Stand With Ukraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/banner2-direct.svg)](https://stand-with-ukraine.pp.ua/)

i18n-tasks helps you find and manage missing and unused translations.

<img width="539" height="331" src="https://i.imgur.com/XZBd8l7.png">

This gem analyses code statically for key usages, such as `I18n.t('some.key')`, in order to:

- Report keys that are missing or unused.
- Pre-fill missing keys, optionally from Google Translate or DeepL (Pro or Free).
- Remove unused keys.

Thus addressing the two main problems of [i18n gem][i18n-gem] design:

- Missing keys only blow up at runtime.
- Keys no longer in use may accumulate and introduce overhead, without you knowing it.

## Table of Contents

- [Quick Start](#quick-start)
- [Commands](#commands)
  - [Check health](#check-health)
  - [Find usages](#find-usages)
  - [Add missing keys](#add-missing-keys)
  - [Translate missing keys](#translate-missing-keys)
  - [Remove unused keys](#remove-unused-keys)
  - [Prune](#prune)
  - [Normalize](#normalize)
  - [Move / rename / merge keys](#move--rename--merge-keys)
  - [Delete keys](#delete-keys)
  - [Compose tasks](#compose-tasks)
- [Configuration](#configuration)
  - [Locales](#locales)
  - [Storage & locale files](#storage--locale-files)
    - [Pattern router](#pattern-router)
    - [Conservative router](#conservative-router)
    - [Isolating router](#isolating-router)
    - [Key pattern syntax](#key-pattern-syntax)
    - [Custom adapters](#custom-adapters)
    - [Rails credentials](#rails-credentials)
  - [Usage search](#usage-search)
    - [Prism-based scanner](#prism-based-scanner)
  - [Fine-tuning](#fine-tuning)
  - [Environment variables & dotenv](#environment-variables--dotenv)
- [Translation backends](#translation-backends)
  - [Google Translate](#google-translate)
  - [DeepL](#deepl)
  - [Yandex](#yandex)
  - [OpenAI](#openai)
  - [watsonx](#watsonx)
- [Features & limitations](#features--limitations)
  - [Relative keys](#relative-keys)
  - [Plural keys](#plural-keys)
  - [Reference keys](#reference-keys)
  - [Dynamic keys](#dynamic-keys)
  - [I18n.localize](#i18nlocalize)
  - [`t()` keyword arguments](#t-keyword-arguments)
  - [Unexpected normalization](#unexpected-normalization)
- [Advanced](#advanced)
  - [Interactive console](#interactive-console)
  - [CSV import / export](#csv-import--export)
  - [Add custom tasks](#add-custom-tasks)
- [Development](#development)

## Quick Start

i18n-tasks can be used with any project using the ruby [i18n gem][i18n-gem] (default in Rails).

1. Add to your `Gemfile`:

   ```ruby
   gem 'i18n-tasks', '~> 1.1.2', group: :development
   ```

2. Copy the default [configuration file](#configuration):

   ```sh
   $ cp $(bundle exec i18n-tasks gem-path)/templates/config/i18n-tasks.yml config/
   ```

3. Run your first health check:

   ```sh
   $ bundle exec i18n-tasks health
   ```

That's it. See [Commands](#commands) for the full list of tasks, or [Configuration](#configuration) to tailor the setup to your project.

**Optional:** copy a test that checks for missing/unused translations on every CI run:

```sh
# RSpec
$ cp $(bundle exec i18n-tasks gem-path)/templates/rspec/i18n_spec.rb spec/

# Minitest
$ cp $(bundle exec i18n-tasks gem-path)/templates/minitest/i18n_test.rb test/
```

## Commands

Run `bundle exec i18n-tasks` to get the list of all the tasks with short descriptions.

### Check health

`bundle exec i18n-tasks health` checks if any keys are missing or not used,
that interpolation variables are consistent across locales,
and that all the locale files are normalized (auto-formatted):

```sh
$ bundle exec i18n-tasks health
```

### Find usages

See where the keys are used with `bundle exec i18n-tasks find`:

```sh
$ bundle exec i18n-tasks find common.help
$ bundle exec i18n-tasks find 'auth.*'
$ bundle exec i18n-tasks find '{number,currency}.format.*'
```

<img width="437" height="129" src="https://i.imgur.com/VxBrSfY.png">

### Add missing keys

Add missing keys with placeholders (base value or humanized key):

```sh
$ bundle exec i18n-tasks add-missing
```

This and other tasks accept arguments:

```sh
$ bundle exec i18n-tasks add-missing -v 'TRME %{value}' fr
```

Pass `--help` for more information:

```sh
$ bundle exec i18n-tasks add-missing --help
Usage: i18n-tasks add-missing [options] [locale ...]
    -l, --locales  Comma-separated list of locale(s) to process. Default: all. Special: base.
    -f, --format   Output format: terminal-table, yaml, json, keys, inspect. Default: terminal-table.
    -v, --value    Value. Interpolates: %{value}, %{human_key}, %{value_or_human_key}, %{key}. Default: %{value_or_human_key}.
    -h, --help     Display this help message.
```

### Translate missing keys

Translate missing keys using a backend service of your choice.

```sh
$ bundle exec i18n-tasks translate-missing

# accepts backend, from and locales options
$ bundle exec i18n-tasks translate-missing --from=base es fr --backend=google
```

Available backends:

- `google` – [Google Translate](#google-translate)
- `deepl` – [DeepL](#deepl)
- `yandex` – [Yandex](#yandex)
- `openai` – [OpenAI](#openai)
- `watsonx` – [watsonx](#watsonx)

### Remove unused keys

```sh
$ bundle exec i18n-tasks unused
$ bundle exec i18n-tasks remove-unused
```

These tasks can infer [dynamic keys](#dynamic-keys) such as `t("category.\#{category.name}")` if you set
`search.strict` to false, or pass `--no-strict` on the command line.

If you want to keep the ordering from the original language file when using remove-unused, pass
`-k` or `--keep-order`.

### Prune keys not in base locale

Remove keys from non-base locales that are absent in the base locale:

```bash
$ i18n-tasks prune
```

Pass `-k` or `--keep-order` to preserve the original key ordering in the locale files.

### Normalize

Sort the keys:

```sh
$ bundle exec i18n-tasks normalize
```

Sort the keys, and move them to the respective files as defined by [`config.write`](#storage--locale-files):

```sh
$ bundle exec i18n-tasks normalize -p
```

### Move / rename / merge keys

`bundle exec i18n-tasks mv <pattern> <target>` is a versatile task to move or delete keys matching the given pattern.

All nodes (leafs or subtrees) matching [`<pattern>`](#key-pattern-syntax) are merged together and moved to `<target>`.

Rename a node (leaf or subtree):

```sh
$ bundle exec i18n-tasks mv user account
```

Move a node:

```sh
$ bundle exec i18n-tasks mv user_alerts user.alerts
```

Move the children one level up:

```sh
$ bundle exec i18n-tasks mv 'alerts.{:}' '\1'
```

Merge-move multiple nodes:

```sh
$ bundle exec i18n-tasks mv '{user,profile}' account
```

Merge (non-leaf) nodes into parent:

```sh
$ bundle exec i18n-tasks mv '{pages}.{a,b}' '\1'
```

### Delete keys

Delete the keys by using the `rm` task:

```sh
$ bundle exec i18n-tasks rm 'user.{old_profile,old_title}' another_key
```

### Compose tasks

`i18n-tasks` also provides composable tasks for reading, writing and manipulating locale data. Examples below.

`add-missing` implemented with `missing`, `tree-set-value` and `data-merge`:

```sh
$ bundle exec i18n-tasks missing -f yaml fr | bundle exec i18n-tasks tree-set-value 'TRME %{value}' | bundle exec i18n-tasks data-merge
```

`remove-unused` implemented with `unused` and `data-remove` (sans the confirmation):

```sh
$ bundle exec i18n-tasks unused -f yaml | bundle exec i18n-tasks data-remove
```

Remove all keys from `fr` that do not exist in `en`. Do not change `en`:

```sh
$ bundle exec i18n-tasks missing -t diff -f yaml en | bundle exec i18n-tasks tree-mv en fr | bundle exec i18n-tasks data-remove
```

See the full list of tasks with `bundle exec i18n-tasks --help`.

## Configuration

Configuration is read from `config/i18n-tasks.yml` or `config/i18n-tasks.yml.erb`.
Inspect the configuration with `bundle exec i18n-tasks config`.

Install the [default config file][config] with:

```sh
$ cp $(bundle exec i18n-tasks gem-path)/templates/config/i18n-tasks.yml config/
```

Settings are compatible with Rails by default.

### Locales

By default, `base_locale` is set to `en` and `locales` are inferred from the paths to data files.
You can override these in the [config][config].

### Storage & locale files

The default data adapter supports YAML and JSON files.

i18n-tasks can manage multiple translation files and read translations from other gems.
To find out more see the `data` options in the [config][config].
NB: By default, only `%{locale}.yml` files are read, not `namespace.%{locale}.yml`. Make sure to check the config.

For writing to locale files i18n-tasks provides three routers.

#### Pattern router

Pattern router organizes keys based on a list of key patterns, as in the example below:

```yaml
data:
  router: pattern_router
  # a list of {key pattern => file} routes, matched top to bottom
  write:
    # write models.* and views.* keys to the respective files
    - ["{models,views}.*", 'config/locales/\1.%{locale}.yml']
    # or, write every top-level key namespace to its own file
    - ["{:}.*", 'config/locales/\1.%{locale}.yml']
    # default, sugar for ['*', path]
    - "config/locales/%{locale}.yml"
```

#### Conservative router

Conservative router keeps the keys where they are found, or infers the path from base locale.
If the key is completely new, conservative router will fall back to pattern router behaviour.
Conservative router is the **default** router.

```yaml
data:
  router: conservative_router
  write:
    - ["devise.*", "config/locales/devise.%{locale}.yml"]
    - "config/locales/%{locale}.yml"
```

If you want to have i18n-tasks reorganize your existing keys using `data.write`, either set the router to
`pattern_router` as above, or run `bundle exec i18n-tasks normalize -p` (forcing the use of the pattern router for that run).

#### Isolating router

Isolating router assumes each YAML file is independent and can contain similar keys.

As a result, the translations are written to an alternate target file for each source file
(only the `%{locale}` part is changed to match target locale). Thus, it is not necessary to
specify any `write` configuration (in fact, it would be completely ignored).

This can be useful for example when using [ViewComponent sidecars](https://viewcomponent.org/guide/translations.html)
(ViewComponent assigns an implicit scope to each sidecar YAML file but `i18n-tasks` is not aware of
that logic, resulting in collisions):

- `app/components/movies_component.en.yml`:

  ```yaml
  en:
    title: Movies
  ```

- `app/components/games_component.en.yml`
  ```yaml
  en:
    title: Games
  ```

This router has a limitation, though: it does not support detecting missing keys from code usage
(since it is not aware of the implicit scope logic).

#### Key pattern syntax

A special syntax similar to file glob patterns is used throughout i18n-tasks to match translation keys:

|   syntax   | description                                              |
| :--------: | :------------------------------------------------------- |
|    `*`     | matches everything                                       |
|    `:`     | matches a single key                                     |
|    `*:`    | matches part of a single key                             |
| `{a, b.c}` | match any in set, can use `:` and `*`, match is captured |

Example of usage:

```sh
$ bundle exec i18n-tasks mv "{:}.contents.{*}_body" "\1.attributes.\2.body"

car.contents.name_body ⮕ car.attributes.name.body
car.contents.description_body ⮕ car.attributes.description.body
truck.contents.name_body ⮕ truck.attributes.name.body
truck.contents.description_body ⮕ truck.attributes.description.body
```

#### Custom adapters

If you store data somewhere but in the filesystem, e.g. in the database or mongodb, you can implement a custom adapter.
If you have implemented a custom adapter please share it on [the wiki][wiki].

#### Rails credentials

If you use Rails credentials and want to load e.g. credentials for translation backends, convert your `i18n-tasks.yml` to `i18n-tasks.yml.erb` and add
a `require "./config/application"` line to load Rails.

```yaml
# config/i18n-tasks.yml.erb
<% require "./config/application" %>

# ...

translation:
  backend: google
  google_translate_api_key: <%= Rails.application.credentials.google_translate_api_key %>
```

### Usage search

i18n-tasks uses an AST scanner for `.rb` and `.html.erb` files, and a regexp scanner for all other files.
New scanners can be added easily: please refer to [this example](https://github.com/glebm/i18n-tasks/wiki/A-custom-scanner-example).

See the `search` section in the [config file][config] for all available configuration options.
NB: By default, only the `app/` directory is searched.

#### Prism-based scanner

There is a scanner based on [Prism](https://github.com/ruby/prism) usable in two different modes.

- `rails` mode parses Rails code and handles context such as controllers, before_actions, model translations and more.
- `ruby` mode parses Ruby code only, and works similar to the existing whitequark/parser-implementation.
- The parser is used for both ruby and ERB files.

##### `rails` mode

It handles the following cases:

- Translations called in `before_actions`
- Translations called in nested methods
- `Model.human_attribute_name` calls
- `Model.model_name.human` calls

Enable it by adding the following to your `config/i18n-tasks.yml`:

```yaml
search:
  prism: "rails"
```

##### `ruby` mode

It finds all `I18n.t`, `I18n.translate`, `t` and `translate` calls in Ruby code. Enable it by adding:

```yaml
search:
  prism: "ruby"
```

The goal is to replace the whitequark/parser-based scanner with this one in the future.

##### Help us out with testing

Please install the latest version of the gem and run `bundle exec i18n-tasks check-prism` which will parse everything with the whitequark/parser-based scanner and then everything with the Prism-scanner and try to compare the results.

Open up issues with any parser crashes, missed translations or false positives.

### Fine-tuning

Add hints to static analysis with magic comment hints (lines starting with `(#|/) i18n-tasks-use` by default):

```ruby
# i18n-tasks-use t('activerecord.models.user') # let i18n-tasks know the key is used
User.model_name.human
```

You can also explicitly ignore keys appearing in locale files via `ignore*` settings.

If you have helper methods that generate translation keys, such as a `page_title` method that returns `t '.page_title'`,
or a `Spree.t(key)` method that returns `t "spree.#{key}"`, use the built-in `PatternMapper` to map these.

For more complex cases, you can implement a [custom scanner][custom-scanner-docs].

See the [config file][config] to find out more.

### Environment variables & dotenv

i18n-tasks supports loading environment variables from `.env` files using the [dotenv](https://github.com/bkeepers/dotenv) gem.
This is particularly useful for storing translation API keys and other sensitive configuration.

If you have `dotenv` in your Gemfile, i18n-tasks will automatically load environment variables from `.env` files
before executing commands. This means you can store your API keys in a `.env` file:

```sh
# .env
GOOGLE_TRANSLATE_API_KEY=your_google_api_key
DEEPL_AUTH_KEY=your_deepl_api_key
OPENAI_API_KEY=your_openai_api_key
```

The dotenv integration works seamlessly – no additional configuration is required. If `dotenv` is not available,
i18n-tasks will continue to work normally using system environment variables.

## Translation backends

### Google Translate

`i18n-tasks translate-missing` requires a Google Translate API key, get it at [Google API Console](https://code.google.com/apis/console).

Where this key is depends on your Google API console:

- Old console: API Access -> Simple API Access -> Key for server apps.
- New console: Nav Menu -> APIs & Services -> Credentials -> Create Credentials -> API Keys -> Restrict Key -> Cloud Translation API

In both cases, you may need to create the key if it doesn't exist.

Put the key in `GOOGLE_TRANSLATE_API_KEY` environment variable or in the config file.

```yaml
# config/i18n-tasks.yml
translation:
  backend: google
  google_translate_api_key: <Google Translate API key>
```

or via environment variable:

```sh
GOOGLE_TRANSLATE_API_KEY=<Google Translate API key>
```

### DeepL

`i18n-tasks translate-missing` requires a DeepL API key. DeepL offers both a Pro plan and a [Free plan](https://www.deepl.com/en/pro#api) (limited to 500,000 characters/month). Get your API key at [DeepL](https://www.deepl.com/en/pro#api). You can specify alias locales if you only use the simple locales internally.

```yaml
# config/i18n-tasks.yml
translation:
  backend: deepl
  deepl_api_key: <DeepL API key>
  deepl_host: <optional, see note below>
  deepl_version: <optional>
  deepl_glossary_ids:
    - uuid
  deepl_options:
    formality: prefer_less
  deepl_locale_aliases:
    en: en-us
    pt: pt-br
```

or via environment variables:

```bash
DEEPL_AUTH_KEY=<DeepL API key>
DEEPL_HOST=<optional, see note below>
DEEPL_VERSION=<optional>
```

> **Free API:** If you are using a DeepL Free account, set `deepl_host` to `https://api-free.deepl.com` (or set the `DEEPL_HOST` environment variable).
>
> ```yaml
> translation:
>   deepl_api_key: "your-free-api-key"
>   deepl_host: "https://api-free.deepl.com"
>   deepl_version: "v2"
> ```

### Yandex

`i18n-tasks translate-missing` requires a Yandex API key, get it at [Yandex](https://tech.yandex.com/translate).

```yaml
# config/i18n-tasks.yml
translation:
  backend: yandex
  yandex_api_key: <Yandex API key>
```

or via environment variable:

```sh
YANDEX_API_KEY=<Yandex API key>
```

### OpenAI

`i18n-tasks translate-missing` requires an OpenAI API key, get it at [OpenAI](https://openai.com/).

```yaml
# config/i18n-tasks.yml
translation:
  backend: openai
  openai_api_key: <OpenAI API key>
  openai_model: <optional>
```

or via environment variable:

```sh
OPENAI_API_KEY=<OpenAI API key>
OPENAI_MODEL=<optional>
```

### watsonx

`i18n-tasks translate-missing` requires a watsonx project and an API key, get it at [IBM watsonx](https://www.ibm.com/watsonx/).

```yaml
# config/i18n-tasks.yml
translation:
  backend: watsonx
  watsonx_api_key: <watsonx API key>
  watsonx_project_id: <watsonx project id>
  watsonx_model: <optional>
```

or via environment variable:

```sh
WATSONX_API_KEY=<watsonx API key>
WATSONX_PROJECT_ID=<watsonx project id>
WATSONX_MODEL=<optional>
```

## Features & limitations

`i18n-tasks` uses an AST scanner for `.rb` and `.html.erb` files, and a regexp-based scanner for other files, such as `.haml`.

### Relative keys

`i18n-tasks` offers support for relative keys, such as `t '.title'`.

✔ Keys relative to the file path they are used in (see [Usage search](#usage-search)) are supported.

✔ Keys relative to `controller.action_name` in Rails controllers are supported. The closest `def` name is used.

### Plural keys

✔ Plural keys, such as `key.{one,many,other,...}` are fully supported.

### Reference keys

✔ Reference keys (keys with `:symbol` values) are fully supported. These keys are copied as-is in
`add/translate-missing`, and can be looked up by reference or value in `find`.

### Dynamic keys

By default, dynamic keys such as `t "cats.#{cat}.name"` are not recognized.
I encourage you to mark these with [i18n-tasks-use hints](#fine-tuning).

Alternatively, you can enable dynamic key inference by setting `search.strict` to `false` in the config. In this case,
all the dynamic parts of the key will be considered used, e.g. `cats.tenderlove.name` would not be reported as unused.
Note that only one section of the key is treated as a wildcard for each string interpolation; i.e. in this example,
`cats.tenderlove.special.name` _will_ be reported as unused.

### I18n.localize

`I18n.localize` is not supported, use [i18n-tasks-use hints](#fine-tuning).
This is because the key generated by `I18n.localize` depends on the type of the object passed in and thus cannot be inferred statically.

### `t()` keyword arguments

✔ `scope` keyword argument is fully supported by the AST scanner, and also by the Regexp scanner but only when it is the first argument.

✔ `default` argument can be used to pre-fill locale files (AST scanner only).

### Unexpected normalization

`i18n-tasks` uses a YAML parser and emitter called `Psych` under the hood. `Psych` has its own heuristic on when
to use `|`, `>`, or `""` for multi-line strings. This can have some unexpected consequences, e.g. when normalizing:

```yaml
a: |
  Lorem ipsum dolor sit amet, consectetur
  Lorem ipsum dolor sit amet, consectetur
b: |
  Lorem ipsum dolor sit amet, consectetur
  Lorem ipsum dolor sit amet, consectetur
```

we get the result:

```yaml
a: |
  Lorem ipsum dolor sit amet, consectetur
  Lorem ipsum dolor sit amet, consectetur
b: "Lorem ipsum dolor sit amet, consectetur \nLorem ipsum dolor sit amet, consectetur\n"
```

The only difference between `a` and `b` is that `b` has an extra trailing space in each line.
This is an unfortunate side effect of `i18n-tasks` using `Psych`.

## Advanced

### Interactive console

`bundle exec i18n-tasks irb` starts an IRB session in i18n-tasks context. Type `guide` for more information.

### CSV import / export

See [i18n-tasks wiki: CSV import and export tasks](https://github.com/glebm/i18n-tasks/wiki/Custom-CSV-import-and-export-tasks).

### Add custom tasks

Tasks that come with the gem are defined in [lib/i18n/tasks/command/commands](lib/i18n/tasks/command/commands).
Custom tasks can be added easily, see the examples [on the wiki](https://github.com/glebm/i18n-tasks/wiki#custom-tasks).

## Development

- Install dependencies using `bundle install`
- Run tests using `bundle exec rspec`
- Install [Overcommit](https://github.com/sds/overcommit) by running `overcommit --install`

### Skip Overcommit hooks

- `SKIP=RuboCop git commit`
- `OVERCOMMIT_DISABLE=1 git commit`

[MIT license]: /LICENSE.txt
[ci]: https://github.com/glebm/i18n-tasks/actions/workflows/tests.yml
[badge-ci]: https://github.com/glebm/i18n-tasks/actions/workflows/tests.yml/badge.svg
[coverage]: https://codeclimate.com/github/glebm/i18n-tasks
[badge-coverage]: https://api.codeclimate.com/v1/badges/5d173e90ada8df07cedc/test_coverage
[config]: https://github.com/glebm/i18n-tasks/blob/main/templates/config/i18n-tasks.yml
[wiki]: https://github.com/glebm/i18n-tasks/wiki "i18n-tasks wiki"
[i18n-gem]: https://github.com/svenfuchs/i18n "svenfuchs/i18n on Github"
[screenshot-i18n-tasks]: https://i.imgur.com/XZBd8l7.png "i18n-tasks screenshot"
[screenshot-find]: https://i.imgur.com/VxBrSfY.png "i18n-tasks find output screenshot"
[adapter-example]: https://github.com/glebm/i18n-tasks/blob/main/lib/i18n/tasks/data/file_system_base.rb
[custom-scanner-docs]: https://github.com/glebm/i18n-tasks/wiki/A-custom-scanner-example
[overcommit]: https://github.com/sds/overcommit#installation
