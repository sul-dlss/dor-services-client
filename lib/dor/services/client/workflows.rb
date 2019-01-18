# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about workflows
      class Workflows < VersionedService
        # Get the initial XML for a workflow
        # @param name [String] the name of the xml
        # @return [String] the response
        def initial(name:)
          resp = connection.get do |req|
            req.url "#{api_version}/workflows/#{name}/initial"
            # asking the service to return XML
            req.headers['Accept'] = 'application/xml'
          end
          return resp.body if resp.success?

          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})"
        end
      end
    end
  end
end
