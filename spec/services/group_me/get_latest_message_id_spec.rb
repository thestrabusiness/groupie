# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupMe::GetLatestMessageId do
  before { VCR.insert_cassette "fetch_messages_without_options" }
  after { VCR.eject_cassette }

  it "returns the id for the latest message" do
    result = GroupMe::GetLatestMessageId.perform(token, group_id)
    expect(result).to eq "158966373163627837"
  end

  def token
    "token"
  end

  def group_id
    "group_id"
  end
end
