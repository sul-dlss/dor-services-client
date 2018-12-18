# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about a repository object
      class Objects
        def initialize(connection:)
          @connection = connection
        end

        attr_reader :connection

        # Creates a new object in DOR
        # @return [HashWithIndifferentAccess] the response, which includes a :pid
        def register(params:)
          resp = connection.post do |req|
            req.url 'v1/objects'
            req.headers['Content-Type'] = 'application/json'
            # asking the service to return JSON (else it'll be plain text)
            req.headers['Accept'] = 'application/json'
            req.body = params.to_json
          end
          raise Error, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})" unless resp.success?

          JSON.parse(resp.body).with_indifferent_access
        end
      end
    end
  end
end
