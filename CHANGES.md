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
