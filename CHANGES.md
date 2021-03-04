## v0.9.34

* Fixes Ruby 3.0 compatibility.
  [#370](https://github.com/glebm/i18n-tasks/issues/370)

## v0.9.33

* Fixes DeepL translation.
  [#367](https://github.com/glebm/i18n-tasks/pull/367)

## v0.9.32

* Support capitalized region names in locale codes (e.g. "zh-YUE")
  [#357](https://github.com/glebm/i18n-tasks/pull/357)
* DeepL: Fix single value translation.
  [#d31297b5](https://github.com/glebm/i18n-tasks/commit/d31297b557687b022e4534927237e4dfd1fdfd23)
* Fix missing key detection for external keys in non-base locale.
  [#364](https://github.com/glebm/i18n-tasks/issues/364)
* `required_ruby_version`: Allow Ruby 3.x.
* Fix deprecation warnings on Ruby 2.7.1.
  [#352](https://github.com/glebm/i18n-tasks/pull/352)

## v0.9.31

* Add Yandex translator backend.
  [#343](https://github.com/glebm/i18n-tasks/pull/343)
* Fix more Ruby 2.7 warnings.
  [#344](https://github.com/glebm/i18n-tasks/pull/344)

## v0.9.30

* Fix keyword arguments warnings in Ruby 2.7.
  [#342](https://github.com/glebm/i18n-tasks/pull/342)
* Recognize `t!` and `translate!` methods.
  [#329](https://github.com/glebm/i18n-tasks/issues/329)
* Test template now tests for inconsistent interpolations.
  [#317](https://github.com/glebm/i18n-tasks/pull/317)

## v0.9.29

* The `remove_unused` command now supports `--pattern`.
  [#327](https://github.com/glebm/i18n-tasks/pull/327)
* Common audio and video file extensions are now ignored.
  [#324](https://github.com/glebm/i18n-tasks/issues/324)
* The test templates for RSpec and minitest now include consistent interpolations check.
  [#317](https://github.com/glebm/i18n-tasks/pull/317)
* Leaf->tree expansion warnings are no longer issued for plural keys (where they are legal).
  [#314](https://github.com/glebm/i18n-tasks/pull/314)
* Single line comments are now ignored in `.js` and `.es6` files.
  Magic comments are still supported (e.g. `// i18n-tasks-use I18n.t('hello')`).
  [#322](https://github.com/glebm/i18n-tasks/issues/322)
* No longer loads all of `rails-i18n` and doesn't set `I18n.enforce_available_locales`,
  fixing some compatibility issues introduced in v0.9.28.
  [#315](https://github.com/glebm/i18n-tasks/issues/315)

## v0.9.28

* The `missing` command now also detects incomplete pluralizations.
  [#308](https://github.com/glebm/i18n-tasks/issues/308)

## v0.9.27

* Fixes `check-consistent-interpolations` when the same interpolation is used more than once.

## v0.9.26

* `eq-base` command now returns a non-zero exit code if there are any results.
  [#301](https://github.com/glebm/i18n-tasks/pull/301)
* New command, `check-consistent-interpolations`, checks that %-interpolations across all locales are consistent.
  The corresponding ignore setting is `ignore_inconsistent_interpolations`.

  This check also runs as part of the `health` command.

  [#304](https://github.com/glebm/i18n-tasks/pull/304)

## v0.9.25

* Adds an optional `--keep-order` (`-k`) parameter to `remove-unused`.
  When passed, keys in the files are not sorted after removing the unused keys.
  [#297](https://github.com/glebm/i18n-tasks/pull/297)
* Drops support for Ruby < 2.3.
  [#298](https://github.com/glebm/i18n-tasks/pull/298)
* Fixes a rare concurrency issue, most easily reproduced on Rubinius.
  [#300](https://github.com/glebm/i18n-tasks/issues/300)
* Avoid Google / DeepL translating empty keys (a minor optimization).
  [#fc529e78](https://github.com/glebm/i18n-tasks/commit/fc529e78d2421ad08e7a93c0164e5d0be1492e40)

## v0.9.24

* Makes `deepl-rb` and `easy_translate` dependencies optional.
  [#296](https://github.com/glebm/i18n-tasks/issues/296)
* Adds DeepL support to `tree-translate`.
* Removes the deprecated `tree-rename-key` command.
* Removes obsolete XSLX report functionality.

## v0.9.23

Fixes DeepL locale handling.
[#49d6d2b6](https://github.com/glebm/i18n-tasks/commit/49d6d2b6afc548b9753b6356a8b51d136b79ba10)

## v0.9.22

Adds the [DeepL](https://www.deepl.com/pro) Machine Translation service.
[#294](https://github.com/glebm/i18n-tasks/pull/294)

You can use it by passing `--backend=deepl` to `translate-missing`:

```bash
i18n-tasks translate-missing --backend deepl
```

Like Google Translate, DeepL also requires an API key. It can be set either via the `DEEPL_AUTH_KEY` environment
variable, or by setting `translation.deepl_api_key` in `i18n-tasks.yml`.

## v0.9.21

Relaxes the `rainbow` dependency version restriction.

## v0.9.20

`i18n-tasks tree-mv` now defaults to matching key patterns including the locale, consistent with other `tree-` commands.
Fixes [#274](https://github.com/glebm/i18n-tasks/issues/274).

Fixes `missing` ignoring the `-t` argument.
[#271](https://github.com/glebm/i18n-tasks/pull/271)

## v0.9.19

Adds a new configuration setting, `data.external`, for locale data from external dependencies (e.g. gems).
This locale data is never considered unused, and is never modified by i18n-tasks.
[#264](https://github.com/glebm/i18n-tasks/issues/264)

Fixes support for calls such as `t @instance_variable, scope: :static_scope` in the non-AST scanner.
[#1d2c6d0c](https://github.com/glebm/i18n-tasks/commit/1d2c6d0cb7ee20a8db68c52e33ec3c2a382633e6)

Fixes `remove-unused` not removing entire files.
[#260](https://github.com/glebm/i18n-tasks/issues/260)

Fixes `normalize` not removing emptied files.
[#263](https://github.com/glebm/i18n-tasks/issues/263)

## v0.9.18

Fixes support for calls such as `t dynamic_key, scope: :static_scope` in the non-AST scanner.
[#255](https://github.com/glebm/i18n-tasks/pull/255)

## v0.9.17

Adds a new task, `check-normalized`, and the corresponding specs, to verify that all the locale files are normalized.
[#249](https://github.com/glebm/i18n-tasks/issues/249)

Fixes an issue with normalization not happening in certain cases.
[#91b593d7](https://github.com/glebm/i18n-tasks/commit/91b593d7259460e2a3aa7fd731d878e8e35707fc)

There is now a minitest template file available.
[#250](https://github.com/glebm/i18n-tasks/pull/250)

Internally, Erubi is now used instead of Erubis for parsing the config file.
[#247](https://github.com/glebm/i18n-tasks/issues/247)

## v0.9.16

Improves handling of interpolations in `translate-missing` when multiple interpolations are present.

## v0.9.15

Adds new configuration options to the built-in scanners to enable support for non-standard messages and receivers.

For example, to support the [`it` gem](https://github.com/iGEL/it):

```ruby
# lib/i18n_tasks_it.rb
# The "it" gem support for i18n-tasks
I18n::Tasks.add_scanner(
  '::I18n::Tasks::Scanners::RubyAstScanner',
  receiver_messages: [nil, AST::Node.new(:const, [nil, :It])].product(%i[it]),
  only: %w[*.rb]
)
I18n::Tasks.add_scanner(
  '::I18n::Tasks::Scanners::PatternWithScopeScanner',
  translate_call: /(?<=^|[^\w'\-.]|[^\w'\-]It\.|It\.)it/,
  exclude: %w[*.rb]
)
```

```yaml
# config/i18n-tasks.yml.erb
<% require './lib/i18n_tasks_it' %>
```

## v0.9.14

* AST scanner: support nested `t` calls in ruby files.
  [#c61f4e00](https://github.com/glebm/i18n-tasks/commit/c61f4e00ee67d7e9963ddb44ed3228f551cc1cad)

* Exclude `*.swf` and `*.flv` files by default.
  [#233](https://github.com/glebm/i18n-tasks/issues/233)

## v0.9.13

This release removes a GPL-licensed dependency, `Term::ANSIColor`, with the MIT-licensed Rainbow gem.

Thanks, @ypresto, for [discovering](https://github.com/glebm/i18n-tasks/issues/234)
and [fixing](https://github.com/glebm/i18n-tasks/pull/235) the issue!

## v0.9.12

This is a minor bugfix release.

* Do not warn about "adding children to leaf" for keys found in source.
  [#228](https://github.com/glebm/i18n-tasks/pull/228)
* Fix an issue with nested keys with the `scope` argument in views.
  [#224](https://github.com/glebm/i18n-tasks/issues/224)

## v0.9.11

This is a minor bugfix release.

* Fixes another issue with the `scope` argument in views.
  [#224](https://github.com/glebm/i18n-tasks/issues/224)

## v0.9.10

This is a minor bugfix release.

* Fixes parenthesized `t()` calls with a `scope` argument in views.
  [#224](https://github.com/glebm/i18n-tasks/issues/224)
* Fixes the `i18n-tasks irb` task.
  [#222](https://github.com/glebm/i18n-tasks/issues/222)

## v0.9.9

This release fixes an issue with dynamic scope arguments in views.

This affects calls like the following:

```erb
<%= t('key', scope: dynamic) %>
```

Previously, i18n-tasks would incorrectly parse it as `key`. Now, such calls are ignored.

[#213](https://github.com/glebm/i18n-tasks/issues/213)

## 0.9.8

This release adds the `mv` command for renaming/moving the keys.
[#116](https://github.com/glebm/i18n-tasks/issues/116)

## 0.9.7

This is a minor bugfix release.

* Fixed `add-missing` command ignoring the locales argument.
  [#205](https://github.com/glebm/i18n-tasks/issues/205)
* Always require `PatternMapper` so that it doesn't need requiring in the config.
  [#204](https://github.com/glebm/i18n-tasks/issues/204)
* If `internal_locale` is set to a locale that's not available, reset it to `en` and print a warning.
  [#202](https://github.com/glebm/i18n-tasks/issues/202)

## 0.9.6

This is a minor bugfix release.

* Fixes the `ignore_lines` PatternScanner feature. [#206](https://github.com/glebm/i18n-tasks/issues/206)
* Allows `:` to be a part of the key. [#207](https://github.com/glebm/i18n-tasks/issues/207)
* Fixes translation of plural HTML keys. [#193](https://github.com/glebm/i18n-tasks/issues/193)

## 0.9.5

* Add a `PatternMapper` scanner for mapping bits of code to keys [#191](https://github.com/glebm/i18n-tasks/issues/191).
* Add missing keys with `nil` value by passing `--nil-value` to `add-missing`. [#170](https://github.com/glebm/i18n-tasks/issues/170)
* Requiring `i18n-tasks` no longer overrides `I18n.locale`. [#190](https://github.com/glebm/i18n-tasks/issues/190).

## 0.9.4

* Improve reporting for reference keys throughout.

## 0.9.3

* Support i18n `:symbol` reference keys. [#150](https://github.com/glebm/i18n-tasks/issues/150)
* Fixes dynamic key matching issue with nested `#{}`. [#180](https://github.com/glebm/i18n-tasks/issues/180)

## 0.9.2

* Fix ActiveSupport >= 4.0 but < 4.2 compatibility. [#178](https://github.com/glebm/i18n-tasks/issues/178)
* Locale file path rewriting now matches locales as directories and multiple instances of the locale in the path. [#176](https://github.com/glebm/i18n-tasks/issues/176) [#177](https://github.com/glebm/i18n-tasks/issues/177)

## 0.9.1

* New method: `I18n::Tasks.add_scanner(scanner_class_name, scanner_opts)` to add a scanner to the default configuration.
* New method: `I18n::Tasks.add_commands(commands_module)` to add commands to `i18n-tasks`.
* Only match `I18n` or `nil` receivers in PatternScanner.

## 0.9.0

* Support for multiple scanners.
* AST scanner for `.rb` files.
* `default:` argument support for `add-missing -v`. AST scanner only.  [#55](https://github.com/glebm/i18n-tasks/issues/55)
* Recognize that only `t` calls can use relative keys, not `I18n.t`. AST scanner only. [#106](https://github.com/glebm/i18n-tasks/issues/106)
* Strict mode enabled by default, can be configured via `search.strict`. New argument: `--no-strict`.
* `search.include` renamed to `search.only`.

## 0.8.7

* New interpolation value for `add-missing -v`: `%{key}`. [Stijn Mathysen](https://github.com/stijnster) [#164](https://github.com/glebm/i18n-tasks/pull/164)
* When adding keys from non-default locales, merge base locale first, then the others. [#162](https://github.com/glebm/i18n-tasks/issues/162)

## 0.8.6

* Report missing keys found in source in all the locales. [#162](https://github.com/glebm/i18n-tasks/issues/162)
* Fix `data-remove` task. [#140](https://github.com/glebm/i18n-tasks/issues/140)
* Non-zero exit code on `health`, `missing`, and `unused` if such keys are present. [#151](https://github.com/glebm/i18n-tasks/issues/151)
* XLSX report compatibility with the OSX Numbers App. [#159](https://github.com/glebm/i18n-tasks/issues/159)
* RSpec template compatibility with `config.expose_dsl_globally = false`. [#148](https://github.com/glebm/i18n-tasks/issues/148)
* `bundle show vagrant` example in the config template is no longer interpolated .[#161](https://github.com/glebm/i18n-tasks/issues/161)

## 0.8.5

* Fix regression: Plugin support [#153](https://github.com/glebm/i18n-tasks/issues/153).

## 0.8.4

* Support relative keys in mailers [#155](https://github.com/glebm/i18n-tasks/issues/155).

## 0.8.3

* Fix regression: ActiveSupport < 4 support [#143](https://github.com/glebm/i18n-tasks/issues/143).

## 0.8.2

* Fix failure on nil values in the data config [#142](https://github.com/glebm/i18n-tasks/issues/142).

## 0.8.1

* The default config file now excludes `app/assets/images` and `app/assets/fonts`. Add `*.otf` to ignored extensions.
* If an error message occurs when scanning, the error message now includes the filename [#141](https://github.com/glebm/i18n-tasks/issues/141).

## 0.8.0

* Parse command line arguments with `optparse`. Remove dependency on Slop.
  Simplified commands DSL: options are mostly passed directly to optparse.
* `search.relative_roots` default changed from from `%w(app/views)` to
  `%w(app/views app/controllers app/helpers app/presenters)`.
* `add-missing` now adds keys detected in source to all locales (previously just base) [#134](https://github.com/glebm/i18n-tasks/issues/134).
* The default spec template no long requires `spec_helper` by default [Daniel Levenson](https://github.com/dleve123) [#135](https://github.com/glebm/i18n-tasks/pull/135).
* `search.exclude` now appends to and not overrides the default exclude list. More extensions excluded by default:
  *.css, *.sass, *.scss, *.less, *.yml, and *.json. [#137](https://github.com/glebm/i18n-tasks/issues/137).

## 0.7.13

* Fix relative keys when controller name consists of more than one word by [Yuji Nakayama](https://github.com/yujinakayama) [#132](https://github.com/glebm/i18n-tasks/pull/132).
* Support keys with UTF8 word characters in the name. [#133](https://github.com/glebm/i18n-tasks/issues/133).
* Change missing report column title from "Details" to "Value in other locales or source", display the locale [#130](https://github.com/glebm/i18n-tasks/issues/130).

## 0.7.12

* Handle relative keys in controllers nested in modules by [Alexander Tipugin](https://github.com/atipugin). [#128](https://github.com/glebm/i18n-tasks/issues/128).
* Only write files that changed [#125](https://github.com/glebm/i18n-tasks/issues/125).
* Allow `[]` in the non-strict scanner pattern [#127](https://github.com/glebm/i18n-tasks/issues/127).

## 0.7.11

* Set slop dependency to 3.5 to ensure Ruby 1.9 compatibility ([#121](https://github.com/glebm/i18n-tasks/pull/121)).
  MRI 1.9 EOL is [February 23, 2015](https://www.ruby-lang.org/en/news/2014/01/10/ruby-1-9-3-will-end-on-2015/).
  We will support 1.9 until rbx and jruby support 2.0.

## 0.7.10

* Support relative keys in controller action with argument

## 0.7.9

* Support relative keys in Rails controller actions by [Jessie A. Young](https://github.com/jessieay). [#46](https://github.com/glebm/i18n-tasks/issues/46).
* Minor fixes

## 0.7.8

* Fix Google Translate issues with non-string keys [#100](https://github.com/glebm/i18n-tasks/pull/100)
* Fix an issue with certain HAML not being parsed [#96](https://github.com/glebm/i18n-tasks/issues/96) [#102](https://github.com/glebm/i18n-tasks/pull/102)
* Fix other minor issues

## 0.7.7

* Fix regression: keys are sorted once again [#92](https://github.com/glebm/i18n-tasks/issues/92).

## 0.7.6

* Add a post-install notice with setup commands
* Fix a small typo in the config template [#91](https://github.com/glebm/i18n-tasks/pull/91).
* Fix `find` crashing on relative keys (regression)

## 0.7.5

Dynamic key usage inference fixes by [Mikko Koski](https://github.com/rap1ds):

* Append `:` to keys ending with dot '.' (to scan `t('category.' + cat)` as `t('category.:')`)
* Consider keys ending with `:` as match expressions
* Make `@` a valid character for keys (to allow `t("category.#{@cat}"`)

## 0.7.4

* Fix `add-missing --help`
* Fix a minor issue with `health` [#88](https://github.com/glebm/i18n-tasks/issues/88)

## 0.7.3

* New task `translate-tree`
* Bugs fixed: [nil values and Google Translate](https://github.com/glebm/i18n-tasks/issues/85), [config file encoding issue](#82).

## 0.7.2

* i18n-tasks now analyses itself! `internal_locale` setting has been added, that controls i18n-tasks reporting language.
English and Russian are available in this release.

## 0.7.1

* 1.9.3 compatibility

## 0.7.0

New tasks:

* `i18n-tasks health` to display missing and unused keys along with other information
* `i18n-tasks tree-` to manipulate trees
* `i18n-tasks data-` to look up and manipulate locale data
* Better `help` for all commands
* Minor bug fixes

Internally:

* Refactored commands DSL
* `add-missing`, `remove-unused` implemented in terms of the new `tree-` commands

## 0.6.3

* Strict mode added for `unused` and `remove-unused`. When passed `-s` or `--strict`, these tasks will not attempt to infer dynamic key usages, such as `t("category.#{category.key}")`.
* Arrays are now supported as values for Google Translate [#77](https://github.com/glebm/i18n-tasks/issues/77)

## 0.6.2

* New task to show locale data: `i18n-tasks data`
* New output format: `keys`, e.g. `i18n-tasks data -fkeys`
* Fix an issue with a top-level dynamic key breaking unused detection [#75](https://github.com/glebm/i18n-tasks/issues/75)
* Document [magic comment hints](https://github.com/glebm/i18n-tasks#fine-tuning)

## 0.6.1

* Fix Google Translate issue with plural keys and missing billing info error

## 0.6.0

* New output format options for reports: yaml, json, and inspect.
* Templates for config and rspec.
* Keys with values same as base locale have been moved from `missing` into a separate task, `eq-base`.
* `missing` now also shows keys that are present in some locale but not in base locale.
* Terminal output: no more Type column in `missing`, first code usage shown for keys missing base value.
* `relative_roots` configuration key moved to `search.relative_roots`, deprecation warning (removed in the next minor).

## 0.5.4

* ActiveSupport 3 compatibility

## 0.5.3

* Fix Google translate regression
* More robust config output

## 0.5.2

* Ignore lines during search with `config.search.ignore_lines`. Ignores comments by default.
* Fixed minor issues with `i18-tasks config` output.

## 0.5.1

* Fix [conservative router](https://github.com/glebm/i18n-tasks#conservative-router).
* Conservative router is now the default.

## 0.5.0

* internals refactored to use trees everywhere
* type `guide` in `i18n-tasks irb` to learn more about the commands
* (remove-)unused tasks now work per locale
* `ignore` settings are shown on `i18n-tasks config`
* Rubinius 2.2.7 compatibility

## 0.4.5

* Respect tty color setting

## 0.4.4

* Fix google translate issues with plural keys and translating from non-base locale

## 0.4.3

* Ruby 1.9 compatibility

## 0.4.2

* Ruby 1.9.3-compatible again

## 0.4.1

* Improved error messages across the board
* Fixed google translate issue with _html keys [#67](https://github.com/glebm/i18n-tasks/issues/67).

## 0.4.0

* In addition to pattern router, a new conservative router that keeps the keys in place. (See [#57](https://github.com/glebm/i18n-tasks/issues/57))
* `i18n-tasks irb` for debugging
* This release is a major refactoring to use real trees internally (as opposed to nested hashes).
Real trees allow for much easier [traversal](/lib/i18n/tasks/data/tree/traversal.rb).
With these trees, information can be associated with each node, which allows for things like the conservative router.
* Accept keys with dashes (`-`) [#64](https://github.com/glebm/i18n-tasks/issues/64).

## 0.3.11

* Improve plural key handling

## 0.3.10

* New (de)serialization options in config
* `add-missing` placeholder argument can now use %{base_value}.

## 0.3.9

* Fix regression: Remove ActiveSupport::HashWithIndifferentAccess from locale data output

## 0.3.8

* Fix activesupport ~3.x compatibility issue (#45).

## 0.3.7

* Catch Errno::EPIPE to allow `i18n-tasks <command> | head` for large reports
* Improved i18n-tasks config output

## v0.3.6

* fix issue with Google Translate

## v0.3.5

* `config.locales` is now picked up by default from paths do data files. `base_locale` defaults to `en`.

## v0.3.3..v0.3.4

* Bugfixes

## v0.3.2

* Tasks that accept locales now accept them as the first argument(s)

## v0.3.0

* i18n-tasks is a binary now (instead of rake tasks). All tasks / commands now accept various options, and there is no need for as many of them as before.
* Works faster on Rails as it doesn't load anything but the gem, but now requires `base_locale` and `locales` to be set in config.

## v0.2.21..v0.2.22

* `rake i18n:usages[pattern]`
* performance regression fixes

## v0.2.20

* `rake i18n:usages` report

## v0.2.17..v0.2.19

* Bugfixes

## v0.2.16

* Key search extracted into its own class, and a custom scanner can now be provided.
* Removed support for deprecated settings

## v0.2.15

* More robust I18n.t call detection (detect I18n.translate and multiline calls)

## v0.2.14

* Google Translate fixes: preserve interpolations, set correct format based on the key (text or html).

## v0.2.13

* New setting relative_roots for relative key resolution (default: %w(app/views))
* fix google translation attempts to translate non-string keys

## v0.2.11 .. v0.2.12

* New task: `i18n:remove_unused`

## v0.2.5..0.2.10

* config/i18n-tasks.yml now processed with ERB
* can now be used with any ruby apps, not just Rails
* more locale formats are considered valid
* `i18n:missing` accepts locales
* `i18n:missing` supports plural keys

## v0.2.4

* more powerful key pattern matching with sets and backtracking

## v0.2.3

* spreadsheet report, tests run on rbx

## v0.2.2

* improved output with terminal-table

## v0.2.1

* fill tasks renamed, fix symbol key search

## v0.2.0

* 3 more prefill tasks, including Google Translate
* tasks renamed

## v0.1.8

* improved search: no longer uses grep, more robust detection (@natano)

## v0.1.7

* ability to route prefill output via data.write config
* multiple configuration variables renamed (still understands old syntax with deprecation warnings)

## v0.1.6

* New key pattern syntax for i18n-tasks.yml a la globbing

## v0.1.5

* Removed get_locale_data, added data configuration options

## v0.1.4

* Fix relative keys in partials (@paulfioravanti)
* Fix i18n:missing when nothing is missing (@tamtamchik)

## v0.1.3

* detect countable keys as used for unused task
* account for non-string keys coming from yaml (thanks @lichtamberg)

## v0.1.2

* added grep config options (thanks @dmke)
* improved terminal output
