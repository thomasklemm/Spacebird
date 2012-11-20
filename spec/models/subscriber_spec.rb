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

require 'spec_helper'

describe Subscriber do
end
