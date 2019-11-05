# frozen_string_literal: true

require 'timeout'

module Dor
  module Services
    class Client
      # A helper for monitoring asynchonous jobs
      class AsyncResult
        attr_reader :url

        # @param [String] url the url of the background result
        def initialize(url:)
          @url = url
        end

        # Polls using exponential backoff, so as not to overrwhelm the server.
        # @param [Float] seconds_between_requests (3.0) initially, how many seconds between polling requests
        # @param [Integer] timeout_in_seconds (180) timeout after this many seconds
        # @param [Float] backoff_factor (2.0) how quickly to backoff.  This should be > 1.0 and probably ought to be <= 2.0
        # @return true if successful false if unsuccessful.
        def wait_until_complete(seconds_between_requests: 3.0,
                                timeout_in_seconds: 180,
                                backoff_factor: 2.0,
                                max_seconds_between_requests: 60)
          poll_until_complete(seconds_between_requests, timeout_in_seconds, backoff_factor, max_seconds_between_requests)
          errors.nil?
        end

        # Checks to see if the result is complete.
        def complete?
          @results = Dor::Services::Client.background_job_results.show(job_id: job_id_from(url: url))
          @results[:status] == 'complete'
        end

        def errors
          @results[:output][:errors]
        end

        private

        def poll_until_complete(seconds_between_requests, timeout_in_seconds, backoff_factor, max_seconds_between_requests)
          interval = seconds_between_requests
          Timeout.timeout(timeout_in_seconds) do
            loop do
              break if complete?

              sleep(interval)
              # Exponential backoff, limited to max_seconds_between_requests
              interval = [interval * backoff_factor, max_seconds_between_requests].min
            end
          end
        rescue Timeout::Error
          @results = { output: { errors: ["Not complete after #{timeout_in_seconds} seconds"] } }
        end

        def job_id_from(url:)
          url.split('/').last
        end
      end
    end
  end
end
