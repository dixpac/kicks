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
      clear_jobs
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
      Sneakers.configure  heartbeat: 2,
                          amqp: "amqp://guest:guest@#{rmq_addr}:5672",
                          vhost: '/',
                          exchange: 'active_jobs_sneakers_int_test',
                          exchange_type: :direct,
                          daemonize: true,
                          threads: 1,
                          workers: 1,
                          pid_path: File.join(Dir.pwd, 'tmp', 'sneakers.pid')

      # Sneakers.configure(amqp: "amqp://guest:guest@#{rmq_addr}:5672")
      # Sneakers.logger.level = Logger::ERROR
    end

    def clear_jobs
      bunny_queue.purge
    end

    def start_workers
      # @pid = fork do
      #   # Require the necessary classes in the child process
      #   require 'fixtures/test_job'
      #
      #   queues = %w[integration_tests]
      #   workers = queues.map do |q|
      #     worker_klass = 'ActiveJobWorker' + OpenSSL::Digest::MD5.hexdigest(q)
      #     Sneakers.const_set(worker_klass, Class.new(ActiveJob::QueueAdapters::SneakersAdapter::JobWrapper) do
      #       from_queue q
      #     end)
      #   end
      #   Sneakers::Runner.new(workers).run
      # end

      queues = %w[integration_tests]
      # workers = queues.map do |q|
      #   worker_klass = 'ActiveJobWorker' + OpenSSL::Digest::MD5.hexdigest(q)
      #   Sneakers.const_set(worker_klass, Class.new(ActiveJob::QueueAdapters::SneakersAdapter::JobWrapper) do
      #     from_queue q
      #   end)
      # end

      byebug
      worker = ActiveJob::QueueAdapters::SneakersAdapter::JobWrapper.from_queue(queues.first)

      Sneakers::Runner.new(worker).run

      begin
        Timeout.timeout(10) do
          sleep 0.5 while bunny_queue.status[:consumer_count] == 0
        end
      rescue Timeout::Error => e
        stop_workers
        puts e
        raise 'Failed to start sneakers worker'
      end
    end

    def stop_workers
      Process.kill 'TERM', @pid
      Process.kill 'TERM', File.open(File.join(Dir.pwd, 'tmp', 'sneakers.pid').to_s).read.to_i
    rescue StandardError
    end

    def bunny_publisher
      @bunny_publisher ||= begin
        p = ActiveJob::QueueAdapters::SneakersAdapter::JobWrapper.send(:publisher)
        p.ensure_connection!
        p
      end
    end

    def bunny_queue
      @queue ||= bunny_publisher.exchange.channel.queue 'integration_tests', durable: true
    end

    def assert_all_accounted_for(opts)
      integration_log 'waiting for publishes to stabilize (5s).'
      sleep 5

      integration_log "polling for changes (max #{opts[:within_sec]}s)."
      pid = opts[:pid]
      opts[:within_sec].times do
        sleep 1
        count = @redis.get(opts[:queue]).to_i
        next unless count == opts[:jobs]

        integration_log "#{count} jobs accounted for successfully."
        Process.kill('TERM', pid)
        sleep 1
        return
      end

      integration_log 'failed test. killing off workers.'
      Process.kill('TERM', pid)
      sleep 1
      raise 'incomplete!'
    end

    it 'aj test' do
      start_workers
      TestJob.perform_later('first')
      # TestJob.perform_now('first')
      sleep 15

      # pid = start_worker(ActiveJob::QueueAdapters::SneakersAdapter::JobWrapper)
      # puts "PID: #{pid}"
      #
      # active_job = TestJob.perform_later('first')
      # byebug
      # integration_log 'publishing thorugh ActiveJob Adapter...'
      #
      # assert_all_accounted_for(
      #   queue: 'integration_tests',
      #   pid: pid,
      #   within_sec: 15,
      #   jobs: 1
      # )
    end
  end
end
