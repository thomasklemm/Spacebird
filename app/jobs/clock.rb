module Clockwork
  every(10.seconds, "Rails.logger.info 'Clockwork works.'")
end



    # app/workers/request_worker.rb
    class RequestWorker
      # Request X from Y
      def self.retrieve_testapp
        # Do anything nescessary to build and execute the request in here
      end
    end

You could then schedule the request with the Heroku Scheduler addon by way of Rails runner (which let's you execute any command in the context of your Rails application.)

    rails runner RequestWorker.retrieve_testapp

    # Read ids string from params hash
    ids = params[:ids]

    # Split string
    ids = ids.split(',')

    # Retrieve products
    if ids.present?
      @products = Product.where(id: ids)
    else
      @products = Product.all
    end


It's not only the table structure that's relevant here, it's also the models and associations

$ rails generate model User name ...
$ rails generate model Item user_id:integer name price_in_cents:integer ...

class User
  has_many :items
end

class Item
  belongs_to :user
end

$ rails g model Bid item_id:integer bidder_id:integer price

class Bid
  belongs_to :bidder, class_name: 'User' # someone comment on this please, maybe a source option is nescessary too
  belongs_to :item
end

class Item
  belongs_to :user
  has_many :bids
end

$ rails g controller ItemsController index show bid

# config/routes.rb
resources :items


class ItemsController
  def bid
    item = Item.find(params[:item_id])

  end
end
