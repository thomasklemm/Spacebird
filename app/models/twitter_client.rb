##
# TwitterClient
#
# Generate a Twitter::Client instance
# with random credentials from Token
# by running 'TwitterClient.random'
#
class TwitterClient
  # Generate a Twitter::Client instance
  # using a random oauth token
  def self.random
    # Find one token
    credentials = self.new.credentials

    # Instantiate and return Twitter client
    if credentials.present?
      @client = Twitter::Client.new(
          oauth_token:        credentials.token,
          oauth_token_secret: credentials.secret
        )
    else
      # else build a twitter client instance with the standard credentials
      Twitter::Client.new
    end
  end

  # Select random credentials
  def credentials
    begin
      rand_id = Token.select(:id).map(&:id).sample
      Token.where("id >= ?", rand_id).first!
    rescue
      Token.first
    end
  end
end
