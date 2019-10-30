# frozen_string_literal: true

require 'timeout'

module Dor
  module Services
    class Client
      # A helper for monitoring asynchonous jobs
      class AsyncResult
        # @param [String] url the url of the background result
        def initialize(url:)
          @url = url
        end

        # @param [Integer] seconds_between_requests (3) how many seconds between polling requests
        # @param [Integer] timeout_in_seconds (180) timeout after this many seconds
        # @return true if successful false if unsuccessful.
        def wait_until_complete(seconds_between_requests: 3, timeout_in_seconds: 180)
          poll_until_complete(seconds_between_requests, timeout_in_seconds)
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

        attr_reader :url, :seconds_between_requests, :timeout_in_seconds

        private

        def poll_until_complete(seconds_between_requests, timeout_in_seconds)
          Timeout.timeout(timeout_in_seconds) do
            loop do
              break if complete?

              sleep(seconds_between_requests)
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
