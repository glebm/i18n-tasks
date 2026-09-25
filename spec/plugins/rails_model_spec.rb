# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "i18n/tasks/plugins/registry"
require "i18n/tasks/plugins/rails_model"

RSpec.describe I18n::Tasks::Plugins::RailsModel do
  let(:tmp_dir) { Dir.mktmpdir("rails_model_spec") }

  after { FileUtils.remove_entry(tmp_dir) }

  # --------------------------------------------------------------------------
  # Helpers
  # --------------------------------------------------------------------------

  def write_model(filename, content)
    path = File.join(tmp_dir, filename)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def build_plugin
    described_class.new(models_paths: ["#{tmp_dir}/**/*.rb"])
  end

  def resolve_key(plugin, key:, candidate_keys: [], **context)
    registry = I18n::Tasks::Plugins::Registry.new
    plugin.register(registry)
    registry.reduce(
      :resolve_model_key,
      {key: key, candidate_keys: candidate_keys},
      **context
    )
  end

  # --------------------------------------------------------------------------
  # Fixture model files
  # --------------------------------------------------------------------------

  before do
    write_model("application_record.rb", <<~RUBY)
      class ApplicationRecord < ActiveRecord::Base
      end
    RUBY

    write_model("location.rb", <<~RUBY)
      class Location < ApplicationRecord
      end
    RUBY

    write_model("base_rack.rb", <<~RUBY)
      class BaseRack < Location
      end
    RUBY

    write_model("operational_rack.rb", <<~RUBY)
      class OperationalRack < BaseRack
      end
    RUBY

    write_model("history_entry.rb", <<~RUBY)
      class HistoryEntry
        include ActiveModel::Model
      end
    RUBY

    write_model("remote/printer.rb", <<~RUBY)
      module Remote
        class Printer < Flexirest::Base
          extend ActiveModel::Translation
        end
      end
    RUBY

    write_model("application_form.rb", <<~RUBY)
      class ApplicationForm
        include ActiveModel::Model
      end
    RUBY

    write_model("devices_form.rb", <<~RUBY)
      class DevicesForm < ApplicationForm
      end
    RUBY

    write_model("devices/transition_form.rb", <<~RUBY)
      module Devices
        class TransitionForm < DevicesForm
        end
      end
    RUBY
  end

  # --------------------------------------------------------------------------
  # Model index building
  # --------------------------------------------------------------------------

  describe "model index" do
    subject(:index) { build_plugin.instance_variable_get(:@model_index) }

    it "recognises the first-level AR class (direct ApplicationRecord child)" do
      expect(index["Location"][:active_record]).to be(true)
      expect(index["Location"][:ar_root]).to be(true)
      expect(index["BaseRack"][:ar_root]).to be(false)
      expect(index["OperationalRack"][:ar_root]).to be(false)
    end

    it "recognises AR ancestry transitively" do
      expect(index["OperationalRack"][:active_record]).to be(true)
      expect(index["BaseRack"][:active_record]).to be(true)
    end

    it "recognises ActiveModel-only class (include ActiveModel::Model)" do
      expect(index["HistoryEntry"][:active_model]).to be(true)
      expect(index["HistoryEntry"][:active_record]).to be(false)
    end

    it "recognises ActiveModel via extend ActiveModel::Translation" do
      expect(index["Remote::Printer"][:active_model]).to be(true)
      expect(index["Remote::Printer"][:active_record]).to be(false)
    end

    it "records the immediate parent name" do
      expect(index["OperationalRack"][:parent]).to eq("BaseRack")
      expect(index["BaseRack"][:parent]).to eq("Location")
      expect(index["Location"][:parent]).to eq("ApplicationRecord")
    end

    it "recognises ActiveModel transitively through the inheritance chain" do
      expect(index["ApplicationForm"][:active_model]).to be(true)
      expect(index["DevicesForm"][:active_model]).to be(true)
      expect(index["Devices::TransitionForm"][:active_model]).to be(true)
      expect(index["Devices::TransitionForm"][:active_record]).to be(false)
    end
  end

  # --------------------------------------------------------------------------
  # STI fallback — human_attribute_name
  # --------------------------------------------------------------------------

  describe "STI candidate keys for human_attribute_name" do
    it "adds intermediate parent keys" do
      result = resolve_key(
        build_plugin,
        key: "activerecord.attributes.operational_rack.name",
        candidate_keys: ["attributes.name"],
        model_constant_name: "OperationalRack",
        call_type: :human_attribute_name,
        attribute_name: "name"
      )
      expect(result[:key]).to eq("activerecord.attributes.operational_rack.name")
      expect(result[:candidate_keys]).to include(
        "attributes.name",
        "activerecord.attributes.base_rack.name",
        "activerecord.attributes.location.name"
      )
    end

    it "uses slash separator for dotted attribute names" do
      result = resolve_key(
        build_plugin,
        key: "activerecord.attributes.operational_rack/status.active",
        candidate_keys: [],
        model_constant_name: "OperationalRack",
        call_type: :human_attribute_name,
        attribute_name: "status.active"
      )
      expect(result[:candidate_keys]).to include(
        "activerecord.attributes.base_rack/status.active",
        "activerecord.attributes.location/status.active"
      )
    end

    it "is a no-op for a direct AR root class (no parents to add)" do
      result = resolve_key(
        build_plugin,
        key: "activerecord.attributes.location.name",
        candidate_keys: ["attributes.name"],
        model_constant_name: "Location",
        call_type: :human_attribute_name,
        attribute_name: "name"
      )
      expect(result[:candidate_keys]).to eq(["attributes.name"])
    end

    it "is a no-op for unknown classes" do
      result = resolve_key(
        build_plugin,
        key: "activerecord.attributes.unknown.name",
        candidate_keys: ["attributes.name"],
        model_constant_name: "Unknown",
        call_type: :human_attribute_name,
        attribute_name: "name"
      )
      expect(result).to eq(
        key: "activerecord.attributes.unknown.name",
        candidate_keys: ["attributes.name"]
      )
    end
  end

  # --------------------------------------------------------------------------
  # STI fallback — model_name
  # --------------------------------------------------------------------------

  describe "STI candidate keys for model_name" do
    it "adds parent model keys as candidates" do
      result = resolve_key(
        build_plugin,
        key: "activerecord.models.operational_rack.one",
        candidate_keys: ["activerecord.models.operational_rack"],
        model_constant_name: "OperationalRack",
        call_type: :model_name
      )
      expect(result[:key]).to eq("activerecord.models.operational_rack.one")
      expect(result[:candidate_keys]).to include(
        "activerecord.models.operational_rack",
        "activerecord.models.base_rack",
        "activerecord.models.location"
      )
    end
  end

  # --------------------------------------------------------------------------
  # ActiveModel namespace correction
  # --------------------------------------------------------------------------

  describe "ActiveModel namespace" do
    it "replaces activerecord with activemodel for ActiveModel-only classes" do
      result = resolve_key(
        build_plugin,
        key: "activerecord.attributes.history_entry.message",
        candidate_keys: ["attributes.message"],
        model_constant_name: "HistoryEntry",
        call_type: :human_attribute_name,
        attribute_name: "message"
      )
      expect(result[:key]).to eq("activemodel.attributes.history_entry.message")
      expect(result[:candidate_keys]).to include("attributes.message")
      expect(result[:candidate_keys]).not_to include(match(/activerecord/))
    end

    it "replaces namespace in candidate_keys too" do
      result = resolve_key(
        build_plugin,
        key: "activerecord.models.history_entry.one",
        candidate_keys: ["activerecord.models.history_entry"],
        model_constant_name: "HistoryEntry",
        call_type: :model_name
      )
      expect(result[:key]).to eq("activemodel.models.history_entry.one")
      expect(result[:candidate_keys]).to eq(["activemodel.models.history_entry"])
    end
  end

  # --------------------------------------------------------------------------
  # active_model_includes config — transitive ActiveModel detection
  # --------------------------------------------------------------------------

  describe "active_model_includes config" do
    before do
      write_model("json_record.rb", <<~RUBY)
        class JsonRecord
          include AttrJson::Model
        end
      RUBY

      write_model("attr_json_models/location_capacity/power.rb", <<~RUBY)
        module AttrJsonModels
          module LocationCapacity
            class Power
              include AttrJson::Model
            end
          end
        end
      RUBY
    end

    it "does not detect the class as ActiveModel without the config" do
      plugin = described_class.new(models_paths: ["#{tmp_dir}/**/*.rb"])
      index = plugin.instance_variable_get(:@model_index)
      expect(index["JsonRecord"][:active_model]).to be(false)
    end

    it "detects the class as ActiveModel when the module is listed in active_model_includes" do
      plugin = described_class.new(
        models_paths: ["#{tmp_dir}/**/*.rb"],
        active_model_includes: ["AttrJson::Model"]
      )
      index = plugin.instance_variable_get(:@model_index)
      expect(index["JsonRecord"][:active_model]).to be(true)
    end

    it "indexes module-wrapped classes only under their fully qualified name" do
      plugin = described_class.new(
        models_paths: ["#{tmp_dir}/**/*.rb"],
        active_model_includes: ["AttrJson::Model"]
      )
      index = plugin.instance_variable_get(:@model_index)
      expect(index["Power"]).to be_nil
      expect(index["AttrJsonModels::LocationCapacity::Power"]).not_to be_nil
      expect(index["AttrJsonModels::LocationCapacity::Power"][:active_model]).to be(true)
    end

    it "corrects the namespace when called with a fully qualified constant name" do
      plugin = described_class.new(
        models_paths: ["#{tmp_dir}/**/*.rb"],
        active_model_includes: ["AttrJson::Model"]
      )
      result = resolve_key(
        plugin,
        key: "activerecord.attributes.attr_json_models/location_capacity/power.value",
        candidate_keys: [],
        model_constant_name: "AttrJsonModels::LocationCapacity::Power",
        call_type: :human_attribute_name,
        attribute_name: "value"
      )
      expect(result[:key]).to eq("activemodel.attributes.attr_json_models/location_capacity/power.value")
    end

    it "corrects the namespace for the class when configured" do
      plugin = described_class.new(
        models_paths: ["#{tmp_dir}/**/*.rb"],
        active_model_includes: ["AttrJson::Model"]
      )
      result = resolve_key(
        plugin,
        key: "activerecord.attributes.json_record.value",
        candidate_keys: ["attributes.value"],
        model_constant_name: "JsonRecord",
        call_type: :human_attribute_name,
        attribute_name: "value"
      )
      expect(result[:key]).to eq("activemodel.attributes.json_record.value")
    end
  end
end
