class UserObserver < ActiveRecord::Observer

  def after_create(user)
    user.give_default_credits
  end

end
