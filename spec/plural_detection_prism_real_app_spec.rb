# frozen_string_literal: true

require "spec_helper"

# Real-app integration tests for Prism-based plural detection.
#
# Each scenario mirrors an issue report and shows the expected behaviour when
# the Prism scanner is (or is not) active.
#
# Issues covered:
#   #473 – defining `one` / `other` reported as missing even when not used as plural
#   #270 – dynamic + plural key: plural forms appear unused (documented limitation)
#   #516 – `other` sub-key causes unused false-positive (documented limitation)
#   #600 – Arabic: only `one`/`other` defined but locale requires more forms
#   #705 – Polish: `one`, `few`, `many` defined but `other` reported missing
RSpec.describe "Plural detection with Prism scanner – real app examples" do
  # Create a BaseTask whose scanner uses Prism and looks in the given paths.
  def prism_task(paths:)
    t = I18n::Tasks::BaseTask.new
    t.config[:search] = {paths: Array(paths), prism: "rails"}
    t
  end

  # Create a BaseTask with the legacy (non-Prism) scanner for comparison.
  def legacy_task(paths:)
    I18n::Tasks::BaseTask.new.tap do |t|
      t.config[:search] = {paths: Array(paths)}
    end
  end

  def missing_plural_keys(task, locales)
    task.missing_plural_forest(locales).leaves.map { |l| l.full_key(root: false) }
  end

  def unused_key_names(task, locale: nil)
    tree = locale ? task.unused_tree(locale: locale) : task.unused_keys
    tree.leaves.map { |l| l.full_key(root: false) }
  end

  # ---------------------------------------------------------------------------
  # Issue #473 – defining `one` (or any plural form) is detected as missing
  # keys even when the translation is never called with count:.
  #
  # Reproduction: a key like `document_count: { one: "1 document" }` has an
  # incomplete plural structure, but the code only calls
  # `t('document_count', title: @doc.title)` (no count:).  The old scanner
  # reported `other` as missing; with Prism we can see there is no plural call.
  # ---------------------------------------------------------------------------
  describe "Issue #473 – partial plural definition used WITHOUT count:" do
    around do |ex|
      TestCodebase.setup(
        "config/locales/en.yml" => {"en" => {
          "document_count" => {"one" => "1 document"}   # missing "other"
        }}.to_yaml,
        "app/controllers/documents_controller.rb" => <<~RUBY
          class DocumentsController < ApplicationController
            def show
              # Used without count: – this is NOT a plural call
              @label = t('document_count', title: @document.title)
            end
          end
        RUBY
      )
      TestCodebase.in_test_app_dir { ex.run }
    ensure
      TestCodebase.teardown
    end

    it "does NOT report missing plural forms when Prism sees no count: argument" do
      task = prism_task(paths: ["app/controllers/documents_controller.rb"])
      expect(missing_plural_keys(task, ["en"])).not_to include("document_count")
    end

    it "DOES report missing plural forms with the legacy scanner (backward-compatible)" do
      task = legacy_task(paths: ["app/controllers/documents_controller.rb"])
      expect(missing_plural_keys(task, ["en"])).to include("document_count")
    end
  end

  # ---------------------------------------------------------------------------
  # Issue #473 – cross-locale variant.
  # Japanese pluralization only requires the `other` key (rails-i18n).
  # A Japanese locale with `notification: { one: "通知" }` triggers a false
  # positive because `one` looks like a plural suffix even though the code
  # never passes count:.
  # ---------------------------------------------------------------------------
  describe "Issue #473 – cross-locale: Japanese partial plural used WITHOUT count:" do
    around do |ex|
      TestCodebase.setup(
        "config/locales/en.yml" => {"en" => {
          "notification" => {"one" => "1 notification", "other" => "%{count} notifications"}
        }}.to_yaml,
        "config/locales/ja.yml" => {"ja" => {
          "notification" => {"one" => "通知"}  # Japanese needs `other`, not `one`
        }}.to_yaml,
        "app/views/notifications/index.html.erb" => <<~ERB
          <p><%= t('notification') %></p>
        ERB
      )
      TestCodebase.in_test_app_dir { ex.run }
    ensure
      TestCodebase.teardown
    end

    it "does NOT report missing `other` for ja when Prism sees no count: in ERB" do
      task = prism_task(paths: ["app/views/notifications/index.html.erb"])
      expect(missing_plural_keys(task, ["ja"])).not_to include("notification")
    end

    it "DOES report missing `other` for ja with the legacy scanner" do
      task = legacy_task(paths: ["app/views/notifications/index.html.erb"])
      expect(missing_plural_keys(task, ["ja"])).to include("notification")
    end
  end

  # ---------------------------------------------------------------------------
  # Issue #473 – mixed usage: the same key is called BOTH with and without
  # count: in different places.  We must still report missing plural forms
  # because at least one call is a genuine plural invocation.
  # ---------------------------------------------------------------------------
  describe "Issue #473 – mixed usage: key called with AND without count:" do
    around do |ex|
      TestCodebase.setup(
        "config/locales/en.yml" => {"en" => {
          "item_count" => {"one" => "1 item"}  # missing "other"
        }}.to_yaml,
        "app/controllers/items_controller.rb" => <<~RUBY
          class ItemsController < ApplicationController
            def index
              @plural_label = t('item_count', count: @items.size)  # plural call
              @singular_label = t('item_count')                    # non-plural call
            end
          end
        RUBY
      )
      TestCodebase.in_test_app_dir { ex.run }
    ensure
      TestCodebase.teardown
    end

    it "DOES report missing plural forms when at least one call uses count:" do
      task = prism_task(paths: ["app/controllers/items_controller.rb"])
      expect(missing_plural_keys(task, ["en"])).to include("item_count")
    end
  end

  # ---------------------------------------------------------------------------
  # Issue #600 – Arabic locale: user deliberately defines only `one` and
  # `other` (because their translation tool, e.g. Weblate, does not support
  # the full Arabic plural set).  When the key IS called with count:, it is
  # correct for i18n-tasks to report the missing forms.
  #
  # This test documents the CURRENT (correct) behaviour: Prism detects the
  # plural call and still flags zero/two/few/many as missing.
  # ---------------------------------------------------------------------------
  describe "Issue #600 – Arabic locale with incomplete plural set used WITH count:" do
    around do |ex|
      TestCodebase.setup(
        "config/locales/en.yml" => {"en" => {
          "documents_found" => {"one" => "1 document found", "other" => "%{count} documents found"}
        }}.to_yaml,
        "config/locales/ar.yml" => {"ar" => {
          # Weblate limitation: only one + other defined
          "documents_found" => {"one" => "وُجد مستند واحد", "other" => "وُجدت %{count} مستندات"}
          # Arabic requires: zero, one, two, few, many, other
        }}.to_yaml,
        "app/views/search/results.html.erb" => <<~ERB
          <p><%= t('documents_found', count: @results.size) %></p>
        ERB
      )
      TestCodebase.in_test_app_dir { ex.run }
    ensure
      TestCodebase.teardown
    end

    it "correctly reports zero/two/few/many as missing for Arabic when count: is used" do
      task = prism_task(paths: ["app/views/search/results.html.erb"])
      missing = missing_plural_keys(task, ["ar"])
      # Arabic requires zero, one, two, few, many, other — only one+other defined
      expect(missing).to include("documents_found")
    end

    it "does NOT report missing plural forms if the key is NOT called with count:" do
      # If the call has no count: (e.g. a bug, but Prism can detect it),
      # the plural check is suppressed — there is no plural invocation.
      TestCodebase.setup(
        "config/locales/en.yml" => {"en" => {
          "documents_found" => {"one" => "1 document", "other" => "%{count} documents"}
        }}.to_yaml,
        "config/locales/ar.yml" => {"ar" => {
          "documents_found" => {"one" => "واحد", "other" => "عدة"}
        }}.to_yaml,
        "app/views/search/results.html.erb" => <<~ERB
          <p><%= t('documents_found') %></p>
        ERB
      )
      task = prism_task(paths: ["app/views/search/results.html.erb"])
      expect(missing_plural_keys(task, ["ar"])).not_to include("documents_found")
    end
  end

  # ---------------------------------------------------------------------------
  # Issue #705 – Polish locale: `one`, `few`, and `many` are defined, but
  # `other` is not.  Polish pluralization requires all four keys (one, few,
  # many, other).  When the key is called with count:, `other` is correctly
  # flagged as missing.
  #
  # This test documents the CURRENT (correct) behaviour.  The issue asks for
  # `other` to not be required when `few` and `many` are present, which is a
  # separate rails-i18n rules concern beyond Prism detection.
  # ---------------------------------------------------------------------------
  describe "Issue #705 – Polish locale: one/few/many defined, other missing, used WITH count:" do
    around do |ex|
      TestCodebase.setup(
        "config/locales/en.yml" => {"en" => {
          "invoice" => {"one" => "Invoice", "other" => "Invoices"}
        }}.to_yaml,
        "config/locales/pl.yml" => {"pl" => {
          # Polish user intentionally omits `other` (rare, always shadowed by few/many)
          "invoice" => {"one" => "Faktura", "few" => "Faktury", "many" => "Faktur"}
        }}.to_yaml,
        "app/views/invoices/index.html.erb" => <<~ERB
          <h1><%= t('invoice', count: @invoices.size) %></h1>
        ERB
      )
      TestCodebase.in_test_app_dir { ex.run }
    ensure
      TestCodebase.teardown
    end

    it "reports `other` as missing for Polish when count: is used (correct behaviour)" do
      task = prism_task(paths: ["app/views/invoices/index.html.erb"])
      expect(missing_plural_keys(task, ["pl"])).to include("invoice")
    end

    it "does NOT report missing `other` for Polish when key is NOT called with count:" do
      TestCodebase.setup(
        "config/locales/en.yml" => {"en" => {
          "invoice" => {"one" => "Invoice", "other" => "Invoices"}
        }}.to_yaml,
        "config/locales/pl.yml" => {"pl" => {
          "invoice" => {"one" => "Faktura", "few" => "Faktury", "many" => "Faktur"}
        }}.to_yaml,
        "app/views/invoices/index.html.erb" => <<~ERB
          <h1><%= t('invoice') %></h1>
        ERB
      )
      task = prism_task(paths: ["app/views/invoices/index.html.erb"])
      expect(missing_plural_keys(task, ["pl"])).not_to include("invoice")
    end
  end

  # ---------------------------------------------------------------------------
  # Issue #270 – dynamic key expression with count: (documented limitation).
  #
  # When the translation call uses a dynamic key (string interpolation), Prism
  # cannot resolve which specific key is being looked up.  The plural sub-keys
  # for that prefix will appear unused because they are not statically
  # reachable.  This is a known limitation of static analysis.
  # ---------------------------------------------------------------------------
  describe "Issue #270 – dynamic key + count: (documented limitation)" do
    around do |ex|
      TestCodebase.setup(
        "config/locales/en.yml" => {"en" => {
          "filters" => {
            "by" => {
              "active" => {"one" => "1 active filter", "other" => "%{count} active filters"},
              "inactive" => {"one" => "1 inactive filter", "other" => "%{count} inactive filters"}
            }
          }
        }}.to_yaml,
        "app/views/filters/index.html.erb" => <<~ERB
          <%# Dynamic key: Prism cannot resolve the specific plural key %>
          <p><%= t("filters.by.\#{filter_type}", count: @items.size) %></p>
        ERB
      )
      TestCodebase.in_test_app_dir { ex.run }
    ensure
      TestCodebase.teardown
    end

    it "does NOT detect specific plural keys used through a dynamic expression (known limitation)" do
      task = prism_task(paths: ["app/views/filters/index.html.erb"])
      used = task.used_tree(strict: true).leaves.map { |l| l.full_key(root: false) }
      # Prism excludes dynamic keys in strict mode – the individual plural sub-keys
      # are not visible to the scanner, so they will appear unused.
      expect(used).not_to include("filters.by.active")
      expect(used).not_to include("filters.by.inactive")
    end

    it "reports filters.by.active / filters.by.inactive as unused (expected limitation)" do
      task = prism_task(paths: ["app/views/filters/index.html.erb"])
      unused = unused_key_names(task, locale: "en")
      # Without locale prefix — both collapse to the key name without locale root
      expect(unused).to include("filters.by.active")
      expect(unused).to include("filters.by.inactive")
    end
  end

  # ---------------------------------------------------------------------------
  # Issue #516 – `other` sub-key in a non-plural translation causes an unused
  # false positive (documented limitation for unused_keys).
  #
  # When a locale has `preferences: { other: "Eile" }` and the base locale has
  # both `other` AND non-plural siblings, the locale-only `{ other: ... }`
  # looks like a collapsed plural node.  The unused-keys check depluraises it
  # to `preferences` which is not in the used-keys tree (the code uses
  # `preferences.posting_defaults`, not `preferences` itself).
  #
  # Note: `missing_plural_forest` is NOT affected for the base locale because
  # `plural_forms?` returns false when non-plural siblings are present.
  # The Prism plural detection helps for the base locale case only.
  # ---------------------------------------------------------------------------
  describe "Issue #516 – `other` sub-key in non-plural translation" do
    around do |ex|
      TestCodebase.setup(
        "config/locales/en.yml" => {"en" => {
          # `other` exists alongside a non-plural sibling – not a plural node
          "preferences" => {"other" => "Other", "posting_defaults" => "Posting defaults"}
        }}.to_yaml,
        "config/locales/ga.yml" => {"ga" => {
          # Irish locale only has `other` – looks like a collapsed plural node
          "preferences" => {"other" => "Eile"}
        }}.to_yaml,
        "app/controllers/preferences_controller.rb" => <<~RUBY
          class PreferencesController < ApplicationController
            def show
              @label = t('preferences.posting_defaults')
            end
          end
        RUBY
      )
      TestCodebase.in_test_app_dir { ex.run }
    ensure
      TestCodebase.teardown
    end

    it "does NOT flag `en.preferences` as needing plural forms (non-plural siblings present)" do
      # English has both `other` and `posting_defaults` → not a plural node →
      # missing_plural_forest does not inspect it at all.
      task = prism_task(paths: ["app/controllers/preferences_controller.rb"])
      expect(missing_plural_keys(task, ["en"])).not_to include("preferences")
    end

    it "flags `ga.preferences` as unused because it looks like a collapsed plural (known limitation)" do
      # Irish only has `{ other: "Eile" }` → plural_forms? returns true →
      # depluralize_key collapses it to `preferences` → `preferences` is not
      # in the used tree (only `preferences.posting_defaults` is) → flagged unused.
      task = prism_task(paths: ["app/controllers/preferences_controller.rb"])
      ga_unused = unused_key_names(task, locale: "ga")
      expect(ga_unused).to include("preferences")
    end
  end
end
