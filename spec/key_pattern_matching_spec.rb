# coding: utf-8
require 'spec_helper'

describe 'Key pattern' do
  include I18n::Tasks::KeyPatternMatching
  describe 'matching' do
    describe '*' do
      it 'as suffix' do
        'devise.*'.should match_key 'devise.some.key'
      end
      it 'as prefix' do
        '*.some.key'.should match_key 'devise.some.key'
      end
      it 'as infix' do
        '*.some.*'.should match_key 'devise.some.key'
      end
      it 'matches multiple namespaces' do
        'a.*.e*'.should match_key 'a.b.c.d.eeee'
      end
    end

    describe ':' do
      it 'as suffix' do
        'a.b.:'.should match_key 'a.b.c'
        'a.b.:'.should_not match_key 'a.b.c.d'
      end

      it 'as prefix' do
        ':.b.c'.should match_key 'a.b.c'
        ':.b.c'.should_not match_key 'x.a.b.c'
      end

      it 'as infix' do
        'a.:.c'.should match_key 'a.b.c'
        'a.:.c'.should_not match_key 'a.b.x.c'
      end
    end

    describe '{sets}' do
      it 'matches' do
        p = 'a.{x,y}.b'
        p.should match_key 'a.x.b'
        p.should match_key 'a.y.b'
        p.should_not match_key 'a.z.b'
      end

      it 'supports :' do
        'a.{:}.c'.should match_key 'a.b.c'
        'a.{:}.c'.should_not match_key 'a.b.x.c'
      end

      it 'supports *' do
        'a.{*}.c'.should match_key 'a.b.c'
        'a.{*}.c'.should match_key 'a.b.x.y.c'
      end

      it 'captures' do
        p = 'a.{x,y}.{:}'
        compile_key_pattern(p) =~ 'a.x.c'
        [$1, $2].should == ['x', 'c']
      end
    end
  end
end