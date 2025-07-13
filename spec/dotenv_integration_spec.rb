# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Dotenv integration" do
  describe "CLI dotenv loading" do
    let(:cli) { I18n::Tasks::CLI.new }

    context "when dotenv is available" do
      it "attempts to load dotenv" do
        # Mock dotenv to be available - using class_double for verification
        mock_dotenv = class_double("Dotenv") # rubocop:disable RSpec/VerifiedDoubleReference
        expect(mock_dotenv).to receive(:load)
        stub_const("Dotenv", mock_dotenv)

        # Mock the require to succeed
        allow(cli).to receive(:require).and_call_original
        allow(cli).to receive(:require).with("dotenv").and_return(true)

        # Call the load_dotenv method directly
        cli.send(:load_dotenv)
      end
    end

    context "when dotenv is not available" do
      it "handles LoadError gracefully" do
        # Mock the require to raise LoadError
        allow(cli).to receive(:require).and_call_original
        allow(cli).to receive(:require).with("dotenv").and_raise(LoadError)

        # Should not raise an error
        expect { cli.send(:load_dotenv) }.not_to raise_error
      end
    end
  end
end
