if defined?(ActiveJob) && ActiveJob.version >= '8.0.0.alpha'
  module ActiveJob
    module QueueAdapters
      # = Sneakers adapter for Active Job
      #
      # To use Sneakers set the queue_adapter config to +:sneakers+.
      #
      #   Rails.application.config.active_job.queue_adapter = :sneakers
      class SneakersAdapter
        def initialize
          @monitor = Monitor.new
        end

        def enqueue(job)
          @monitor.synchronize do
            JobWrapper.from_queue job.queue_name
            JobWrapper.enqueue ActiveSupport::JSON.encode(job.serialize)
          end
        end

        def enqueue_at(job, timestamp)
          raise NotImplementedError, 'This queueing backend does not support scheduling jobs.'
        end

        class JobWrapper
          include Sneakers::Worker
          from_queue 'default'

          def work(msg)
            job_data = ActiveSupport::JSON.decode(msg)
            Base.execute job_data
            ack!
          end
        end
      end
    end
  end
end
