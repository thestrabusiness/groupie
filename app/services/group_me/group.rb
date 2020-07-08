# frozen_string_literal: true

module GroupMe
  class Group < Base
    def initialize(data)
      self.data = data
    end
  end
end
