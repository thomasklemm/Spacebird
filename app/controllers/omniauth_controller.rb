class OmniauthController < Devise::OmniauthCallbacksController
  # Handle callback from Twitter oauth
  def twitter
    # Login or create subscriber from omniauth
    omniauth = request.env['omniauth.auth']
    @subscriber = Subscriber.find_or_create_subscriber_from_twitter(omniauth)

    # Did our subscriber just authenticate successfully?
    if @subscriber.persisted?
      # Yes.
      flash.notice = "Hello, #{ @subscriber.name }. Great to have you here! :-D Go have a look around."
      # Persist login in ...
      @subscriber.remember_me = true
      sign_in_and_redirect @subscriber, event: :authentication
    else
      # No.
      flash.alert = "Twitter Authentication error. Please email human@spacemonkeys.io if you see this error. Thanks for your time and help!"
      redirect_to root_url
    end
  end
end
