require File.expand_path('../../config/boot',        __FILE__)
require File.expand_path('../../config/environment', __FILE__)
require 'clockwork'

include Clockwork

# Recurring update of all known Twitter users
# can be with Heroku scheduler as well every 10 minutes
# by calling 'rails runner RecurringUpdateAllUsersWorker.perform_async'
every(15.minutes, 'Recurring update of all users') { RecurringUpdateAllUsersWorker.perform_async }
