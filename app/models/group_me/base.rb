module GroupMe
  BASE_API_URL = "https://api.groupme.com/v3".freeze

  class Base
    attr_accessor :data

    def respond_to_missing?
      true
    end

    def method_missing(method, *args, &block)
      if data.keys.include?(method.to_s)
        return data[method.to_s]
      end

      super
    end

    private

    def current_user_url(access_token)
      "#{BASE_API_URL}/users/me?token=#{access_token}"
    end
  end
end
