# coding: utf-8
require 'spec_helper'

describe 'Key pattern' do
  include I18n::Tasks::KeyPatternMatching
  describe 'matching' do
    describe '*' do
      it 'as suffix' do
        expect('devise.*').to match_key 'devise.some.key'
      end
      it 'as prefix' do
        expect('*.some.key').to match_key 'devise.some.key'
      end
      it 'as infix' do
        expect('*.some.*').to match_key 'devise.some.key'
      end
      it 'matches multiple namespaces' do
        expect('a.*.e*').to match_key 'a.b.c.d.eeee'
      end
    end

    describe ':' do
      it 'as suffix' do
        expect('a.b.:').to match_key 'a.b.c'
        expect('a.b.:').not_to match_key 'a.b.c.d'
      end

      it 'as prefix' do
        expect(':.b.c').to match_key 'a.b.c'
        expect(':.b.c').not_to match_key 'x.a.b.c'
      end

      it 'as infix' do
        expect('a.:.c').to match_key 'a.b.c'
        expect('a.:.c').not_to match_key 'a.b.x.c'
      end
    end

    describe '{sets}' do
      it 'matches' do
        p = 'a.{x,y}.b'
        expect(p).to match_key 'a.x.b'
        expect(p).to match_key 'a.y.b'
        expect(p).not_to match_key 'a.z.b'
      end

      it 'supports :' do
        expect('a.{:}.c').to match_key 'a.b.c'
        expect('a.{:}.c').not_to match_key 'a.b.x.c'
      end

      it 'supports *' do
        expect('a.{*}.c').to match_key 'a.b.c'
        expect('a.{*}.c').to match_key 'a.b.x.y.c'
      end

      it 'captures' do
        p = 'a.{x,y}.{:}'
        compile_key_pattern(p) =~ 'a.x.c'
        expect([$1, $2]).to eq(['x', 'c'])
      end
    end
  end
end