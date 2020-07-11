# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupMe::FetchAllMessages do
  context "when the response contains message data" do
    it "returns the accumulated messages" do
      allow(GroupMe::GetLatestMessageId).to receive(:perform).and_return(1)
      allow(GroupMe::MessageFetcher).to receive(:perform).and_return(message_result, [])

      results = GroupMe::FetchAllMessages.perform("token", "group_id")

      expect(results.map(&:id)).to match_array [ "1", "2" ]
    end
  end

  def message_result
    [
      { "id" => "1" },
      { "id" => "2" }
    ]
  end
end
