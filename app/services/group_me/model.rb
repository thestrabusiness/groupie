# frozen_string_literal: true

module GroupMe
  class Model
    attr_accessor :data

    def respond_to_missing?
      true
    end

    def method_missing(method, *args, &block)
      if data.respond_to?(:keys) && data.keys.include?(method.to_s)
        return data[method.to_s]
      end

      super
    end
  end
end
