# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe "I18n::Tasks::Scanners::RubyScanner" do
  describe "#scan_file" do
    subject do
      I18n::Tasks::Scanners::RubyScanner.new.send(:scan_file, tempfile.path)
    end

    let(:tempfile) do
      tempfile = Tempfile.new
      tempfile.write(source)
      tempfile.flush
      tempfile
    end

    context "when source contains I18n.t calls" do
      let(:source) do
        <<~RUBY
          I18n.t("foo")
        RUBY
      end

      it { is_expected.to be_present }
    end

    context "when source contains ::I18n.t calls" do
      let(:source) do
        <<~RUBY
          ::I18n.t("foo")
        RUBY
      end

      it { is_expected.to be_present }
    end
  end
end
