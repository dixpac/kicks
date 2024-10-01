require 'spec_helper'
require 'sneakers'
require 'sneakers/runner'
require 'rabbitmq/http/client'
require 'timeout'
require 'active_job'
require 'active_job/queue_adapters/sneakers_adapter'
require 'fixtures/test_job'

describe 'active job integration' do
  describe 'first' do
    before :each do
      skip unless ENV['INTEGRATION']
      prepare
    end

    def integration_log(msg)
      puts msg if ENV['INTEGRATION_LOG']
    end

    def rmq_addr
      @rmq_addr ||= compose_or_localhost('rabbitmq')
    end

    def prepare
      ActiveJob::Base.queue_adapter = :sneakers

      Sneakers.clear!
      Sneakers.configure(amqp: "amqp://guest:guest@#{rmq_addr}:5672")
      Sneakers.logger.level = Logger::ERROR

      redis_addr = compose_or_localhost('redis')
      @redis = Redis.new(host: redis_addr)
      @redis.del('rails_active_job')
    end

    def start_active_job_workers
      integration_log 'starting workers.'
      r = Sneakers::Runner.new([ActiveJob::QueueAdapters::SneakersAdapter::JobWrapper], {})
      pid = fork do
        r.run
      end

      integration_log 'waiting for workers to stabilize (5s).'
      sleep 5

      pid
    end

    it 'aj test' do
      pid = start_active_job_workers
      TestJob.perform_later('Hello Rails!')
      sleep 3

      Process.kill('TERM', pid)

      assert_equal @redis.get('rails_active_job').to_i, 1
    end
  end
end
