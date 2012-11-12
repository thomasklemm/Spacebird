class Subscriber < ActiveRecord::Base
  # Include Devise modules
  devise :rememberable, :trackable, :omniauthable

  # Validations
  validates :username, uniqueness: true

  # Field defaults
  def name
    self[:name] || username
  end

  # Authentications
  has_many :authentications

  # Find or create subscriber
  # through Twitter oauth
  # and create respective authentications
  def self.find_or_create_subscriber_from_twitter(omniauth)
    # Find authentication
    authentication = Authentication.find_by_provider_and_uid(omniauth.provider, omniauth.uid)

    # Return subscriber
    if authentication && authentication.subscriber
      authentication.subscriber
    # If Twitter user not yet a subscriber
    else
      # Create subscriber
      subscriber = Subscriber.create! do |s|
        s.username   = omniauth.info.nickname
        s.name       = omniauth.info.name
        s.image_url  = omniauth.info.image
      end

      # Create authentication
      subscriber.authentications.create! do |a|
        a.provider = omniauth.provider
        a.uid      = omniauth.uid
      end

      # Return subscriber
      subscriber.save
      subscriber
    end
  end

  # Accessible attributes
  attr_accessible :username, :name, :image_url
end
