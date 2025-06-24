# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls around workflows in DOR
      class Workflows < VersionedService
        # Retrieves a list of workflow template name
        # @return [Array<String>] the list of templates
        def templates
          resp = connection.post do |req|
            req.url "#{api_version}/workflow_templates"
            req.headers['Content-Type'] = 'application/json'
            req.headers['Accept'] = 'application/json'
          end
          raise_exception_based_on_response!(resp) unless resp.success?

          JSON.parse(resp.body)
        end
      end
    end
  end
end
