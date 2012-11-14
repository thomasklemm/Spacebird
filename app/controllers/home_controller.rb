class HomeController < ApplicationController
  layout 'theme/application'

  def index
    # Subscriber
    @subscriber = current_subscriber ? User.find_by_twitter_id(current_subscriber.twitter_id) : User.first
  end
end
