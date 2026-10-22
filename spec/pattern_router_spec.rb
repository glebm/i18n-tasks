# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Pattern router" do
  let(:router) do
    I18n::Tasks::Data::Router::PatternRouter.new(
      nil,
      write: [
        ["devise.*", "config/locales/devise.%{locale}.yml"],
        ["{:}.*", 'config/locales/\1.%{locale}.yml'],
        "config/locales/%{locale}.yml"
      ]
    )
  end

  let(:forest) do
    build_tree(en: {
      devise: {sign_in: "Sign in", errors: {locked: "Locked"}},
      shop: {cart: {empty: "Empty", total: "Total"}, title: "Shop"},
      admin: {title: "Admin"}
    })
  end

  it "routes each key to its destination, keeping the slices apart" do
    slices = router.route("en", forest).to_h { |path, tree| [path, tree.to_hash] }
    expect(slices).to eq(
      "config/locales/devise.en.yml" => {"en" => {"devise" => {"sign_in" => "Sign in", "errors" => {"locked" => "Locked"}}}},
      "config/locales/shop.en.yml" => {"en" => {"shop" => {"cart" => {"empty" => "Empty", "total" => "Total"}, "title" => "Shop"}}},
      "config/locales/admin.en.yml" => {"en" => {"admin" => {"title" => "Admin"}}}
    )
  end

  it "fails on a key no route matches" do
    router = I18n::Tasks::Data::Router::PatternRouter.new(nil, write: [["devise.*", "config/locales/devise.%{locale}.yml"]])
    expect { router.route("en", forest).to_a }.to raise_error(I18n::Tasks::CommandError, /Cannot route key shop\.cart\.empty/)
  end
end
