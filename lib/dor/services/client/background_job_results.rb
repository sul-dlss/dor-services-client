# frozen_string_literal: true

require 'json'

module Dor
  module Services
    class Client
      # API calls around background job results from dor-services-app
      class BackgroundJobResults < VersionedService
        # Get status/result of a background job
        # @param job_id [String] required string representing a job identifier
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        # @return [String] result of background job
        def show(job_id:)
          resp = connection.get do |req|
            req.url "#{api_version}/background_job_results/#{job_id}"
            req.headers['Accept'] = 'application/json'
          end

          return JSON.parse(resp.body).with_indifferent_access if resp.success?

          raise_exception_based_on_response!(resp)
        end

        private

        def raise_exception_based_on_response!(response)
          raise (response.status == 404 ? NotFoundResponse : UnexpectedResponse),
                ResponseErrorFormatter.format(response: response)
        end
      end
    end
  end
end
