class User < ApplicationRecord
  include Clearance::User

  def skip_password_validation?
    true
  end

  def group_member?(group_id)
    group_ids.include?(group_id)
  end
end
