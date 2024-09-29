require 'sneakers'

class TestJob < ActiveJob::Base
  self.queue_adapter = :sneakers
  queue_as :integration_tests

  def perform(_msg)
    byebug
    puts '***********' * 100
    # $redis.incr(self.class.queue_name)
  end
end
