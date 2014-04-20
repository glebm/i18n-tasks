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
