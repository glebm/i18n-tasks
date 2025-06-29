# frozen_string_literal: true

require "spec_helper"
require "i18n/tasks/scanners/ruby_key_literals"

RSpec.describe "RubyKeyLiterals" do
  let(:scanner) do
    Object.new.extend I18n::Tasks::Scanners::RubyKeyLiterals
  end

  describe "#valid_key?" do
    it "allows forward slash in key" do
      expect(scanner).to be_valid_key("category/product")
    end

    context "with spaces in key" do
      it "allows plain string" do
        expect(scanner).to be_valid_key("key with spaces")
      end

      it "allows Unicode characters" do
        expect(scanner).to be_valid_key("привет мир 你好 世界")
      end

      it "allows mixed ASCII and Unicode" do
        expect(scanner).to be_valid_key("product カテゴリー with スペース")
      end

      it "allows numbers and Unicode" do
        expect(scanner).to be_valid_key("項目123 テスト 456")
      end
    end

    context "with various writing systems" do
      it "allows right-to-left text" do
        expect(scanner).to be_valid_key("مرحبا بالعالم")
      end

      it "allows mixed direction text" do
        expect(scanner).to be_valid_key("Hello مرحبا 世界")
      end
    end
  end
end
