class User < ApplicationRecord
  include Clearance::User

  def skip_password_validation?
    true
  end
end
