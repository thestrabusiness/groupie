# frozen_string_literal: true

require "rails_helper"

RSpec.describe GroupMe::FetchMessagesSince do
  context "when the response contains message data" do
    it "saves the messages" do
      Group.create(name: "test group")
      allow(GroupMe::MessageFetcher).to receive(:perform).and_return(message_result, [])

      GroupMe::FetchMessagesSince.perform("token", "group_id", "after_id")

      expect(Message.count).to eq 2
      expect(Message.pluck(:text)).to eq ["a message", "another message"]
    end
  end

  def message_result
    [
      {
        "id" => "1",
        "group_id" => Group.first.id,
        "user_id" => "3",
        "avatar_url" => "image.jpg",
        "text" => "a message",
        "name" => "sender name",
        "favorited_by" => ["1"],
        "attachments" => [],
        "created_at" => 1594563544,
      },
      {
        "id" => "2",
        "group_id" => Group.first.id,
        "user_id" => "4",
        "avatar_url" => "image.jpg",
        "text" => "another message",
        "name" => "sender name",
        "favorited_by" => ["2,3,4"],
        "attachments" => [],
        "created_at" => 1594563560,
      },
    ]
  end
end
