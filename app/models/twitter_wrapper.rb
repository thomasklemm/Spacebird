##
# TwitterWrapper
#
# Usage:
# t = TwitterWrapper.new(twitter_id)
# Param twitter_id is optional, the respective token will be used if provided.
# A random token is selected if no or an invalid twitter_id is provided.
#
# Attributes:
# t.token  => Selected Token instance
# t.client => Twitter::Client instance with matching Oauth credentials
# t.twitter_id => Selected twitter_id
#
class TwitterWrapper
  attr_reader :token, :client, :twitter_id

  def initialize(twitter_id = nil)
    @token = find_token(twitter_id)
    @client = Twitter::Client.new(
        oauth_token:         @token.token,
        oauth_token_secret:  @token.secret
      )
    @twitter_id = @token.twitter_id
  end

  def find_token(twitter_id = nil)
    token = Token.find_by_twitter_id(twitter_id) if twitter_id.present?
    (token && token.token) ? token : random_token
  end

  def random_token
    Token.offset(random_offset).limit(1).first # is there another to execute the query, else relation is returned
  end

  def random_offset
    rand(Token.count - 1)
  end
end
