# == Schema Information
#
# Table name: subscribers
#
#  id                  :integer          not null, primary key
#  username            :string(255)
#  name                :string(255)
#  image_url           :string(255)
#  twitter_id          :integer
#  remember_token      :string(255)
#  remember_created_at :datetime
#  sign_in_count       :integer          default(0)
#  current_sign_in_at  :datetime
#  last_sign_in_at     :datetime
#  current_sign_in_ip  :string(255)
#  last_sign_in_ip     :string(255)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class Subscriber < ActiveRecord::Base
  # Include Devise modules
  devise :rememberable, :trackable, :omniauthable

  # Validations
  validates :username, uniqueness: true

  # Field defaults
  def name
    self[:name] || username
  end

  ##
  # Associastions
  #
  # Authentications
  has_many :authentications, dependent: :destroy

  # Token
  has_one :token, dependent: :destroy

  ##
  # Instance methods
  #
  # Create authentication from omniauth hash
  def create_authentication(omniauth)
    authentications.create! do |a|
      a.provider = omniauth.provider
      a.uid      = omniauth.uid
    end
  end

  # Create or update token from omniauth hash
  def create_or_update_token(omniauth)
    # Update token if present
    if token
      token.update_attributes(
        twitter_id: omniauth.uid.to_i,
        token:      omniauth.credentials.token,
        secret:     omniauth.credentials.secret
      )
    # or create token
    else
      create_token do |t|
        t.twitter_id = omniauth.uid.to_i
        t.token      = omniauth.credentials.token
        t.secret     = omniauth.credentials.secret
      end
    end
  end


  # Find or create subscriber through Twitter oauth
  def self.find_or_create_subscriber_from_twitter(omniauth)
    # Find authentication
    authentication = Authentication.find_by_provider_and_uid(omniauth.provider, omniauth.uid)

    # If authentication and subscriber are present...
    if authentication && authentication.subscriber
      subscriber = authentication.subscriber

      # ... create or update their oauth token
      subscriber.create_or_update_token(omniauth)

      # ... and exit returning the subscriber instance
      return subscriber
    end

    # Create the subscriber if not present yet
    subscriber = Subscriber.create! do |s|
      s.username   = omniauth.info.nickname
      s.name       = omniauth.info.name
      s.image_url  = omniauth.info.image
      s.twitter_id = omniauth.extra.raw_info.id.to_i
    end

    # Create authentication
    subscriber.create_authentication(omniauth)

    # Create token
    subscriber.create_or_update_token(omniauth)

    # Create or update user from omniauth
    # and set subscriber flag
    User.create_or_update_from_omniauth(omniauth)

    # Return subscriber
    subscriber.save
    subscriber
  end

  # Accessible attributes
  attr_accessible :username, :name, :image_url
end
