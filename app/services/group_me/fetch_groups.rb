# frozen_string_literal: true

require "net/http"

module GroupMe
  class FetchGroups < Api
    def self.perform(access_token)
      new.perform(access_token, 1, [])
    end

    def perform(access_token, page, acc = [])
      groups_url = build_group_url(access_token, page)
      response = Net::HTTP.get_response(groups_url)

      return unless response.code == "200"

      group_data = JSON.parse(response.body)["response"]
      if group_data.empty?
        acc
      else
        groups = group_data.map { |group| Group.new(group) }
        perform(access_token, page + 1, acc + groups)
      end
    end

    private

    def build_group_url(token, page)
      URI("#{BASE_API_URL}/groups?token=#{token}&page=#{page}&per_page=100")
    end
  end
end
