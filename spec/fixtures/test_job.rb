require 'sneakers'
require 'redis'

redis_addr = compose_or_localhost('redis')
puts "REDIS is at #{redis_addr}"
$redis = Redis.new(host: redis_addr)

# module JobBuffer
#   class << self
#     def clear
#       values.clear
#     end
#
#     def add(value)
#       values << value
#     end
#
#     def values
#       @values ||= []
#     end
#   end
# end

class TestJob < ActiveJob::Base
  self.queue_adapter = :sneakers
  # queue_as :integration_tests

  def perform(message)
    $redis.incr('rails_active_job')
    # JobBuffer.add(message)
  end
end
