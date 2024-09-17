require 'rails'
require 'active_job'
require 'active_job/queue_adapters/sneakers_adapter'

module Sneakers
  class Rails < ::Rails::Engine
  end
end
