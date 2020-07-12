# frozen_string_literal: true

module GroupMe
  class Message < Model
    def initialize(data)
      self.data = data
    end
  end
end
