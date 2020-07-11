# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupMe::MessageFetcher do
  context "with a successful response" do
    before { VCR.insert_cassette "fetch_messages_without_options" }
    after { VCR.eject_cassette }

    it "returns parsed message data" do
      result = GroupMe::MessageFetcher.perform(token, group_id)

      expect(result).to_not be_empty
    end
  end

  context "with a non-200 response" do
    before { VCR.insert_cassette "fetch_messages_with_empty_response" }
    after { VCR.eject_cassette }

    it "returns an empty array" do
      result = GroupMe::MessageFetcher.perform(token, group_id)

      expect(result).to be_empty
    end
  end

  def token
    "token"
  end

  def group_id
    "group_id"
  end
end
