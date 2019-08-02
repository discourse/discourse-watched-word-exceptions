# frozen_string_literal: true
require 'rails_helper'

describe WordWatcher do
  before { SiteSetting.watched_word_exceptions_enabled = true }
  after do
    $redis.flushall
  end

  describe '.word_matcher_regexp' do
    let!(:word1) { Fabricate(:watched_word, action: WatchedWord.actions[:block], word: "test1").word }
    let!(:word2) { Fabricate(:watched_word, action: WatchedWord.actions[:block], word: "dis*").word }

    context "without exceptions" do
      it "works" do
        expect(WordWatcher.new("string with test1 in it").should_block?).to eq(["test1"])
        expect(WordWatcher.new("string with disgusting in it").should_block?).to eq(["disgusting"])
        expect(WordWatcher.new("string with discourse in it").should_block?).to eq(["discourse"])
      end
    end

    context "with an exception" do
      let!(:word3) { Fabricate(:watched_word, action: WatchedWord.actions[:exceptions], word: "discourse") }
      it "works" do
        expect(WordWatcher.new("string with test1 in it").should_block?).to eq(["test1"])
        expect(WordWatcher.new("string with disgusting in it").should_block?).to eq(["disgusting"])
        expect(WordWatcher.new("string with discourse in it").should_block?).to eq(nil)
      end
    end
  end
end
