# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupMe::FetchGroups do
  context "when the response contains group data" do
    before { VCR.insert_cassette "fetch_groups_with_groups" }
    after { VCR.eject_cassette }

    it "makes another call to #perform" do
      fetcher = GroupMe::FetchGroups.new
      expect(fetcher).to receive(:perform).twice.and_call_original
      fetcher.perform(access_token, 1, [])
    end
  end

  context "when the response does not contain group data" do
    before { VCR.insert_cassette "fetch_groups_empty" }
    after { VCR.eject_cassette }

    it "does not make another call to #perform" do
      fetcher = GroupMe::FetchGroups.new
      expect(fetcher).to receive(:perform).once.and_call_original
      fetcher.perform(access_token, 1, [])
    end

    it "returns the accumulated groups" do
      fetcher = GroupMe::FetchGroups.new
      expect(fetcher).to receive(:perform).once.and_call_original
      results = fetcher.perform(access_token, 1, ["stuff"])
      expect(results).to eq ["stuff"]
    end
  end

  def access_token
    "token"
  end
end
