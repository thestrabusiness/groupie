require "net/http"

module GroupMe
  class MessageFetcher < Base
    attr_accessor :group_id, :access_token, :options

    MESSAGE_LIMIT = 100

    def self.perform(access_token, group_id, options = {})
      new(access_token, group_id, options).perform
    end

    def initialize(access_token, group_id, options)
      @group_id = group_id
      @options = options
      @access_token = access_token
    end

    def perform
      uri = URI(messages_url)
      response = Net::HTTP.get_response(uri)

      if response.code == "200"
        return JSON.parse(response.body)["response"]["messages"]
      end

      []
    end

    private

    def messages_url
      [
        "#{BASE_API_URL}/groups/#{group_id}/messages?#{token_param}",
        limit_param,
        option_params
      ].reject(&:empty?).join("&")
    end

    def token_param
      "token=#{access_token}"
    end

    def limit_param
      "limit=#{MESSAGE_LIMIT}"
    end

    def option_params
      options.map { |param, value| "#{param}=#{value}" }
    end
  end
end
