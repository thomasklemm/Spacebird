web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: bundle exec sidekiq -c 100
clock: bundle exec clockwork lib/clock.rb

