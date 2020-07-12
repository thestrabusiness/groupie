# frozen_string_literal: true

module GroupMe
  class Group < Model
    def initialize(data)
      self.data = data
    end
  end
end
