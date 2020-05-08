# frozen_string_literal: true

require 'active_support/json' # required for serializing time as iso8601

module Dor
  module Services
    class Client
      # API calls that are about searching AdministrativeTags
      class AdministrativeTagSearch < VersionedService
        # rubocop:disable Naming/UncommunicativeMethodParamName
        def search(q:)
          resp = connection.get do |req|
            req.url "#{api_version}/administrative_tags/search?q=#{q}"
          end

          # Since argo is using this as a proxy, no need to parse the response.
          return resp.body if resp.success?

          raise_exception_based_on_response!(resp)
        end
        # rubocop:enable Naming/UncommunicativeMethodParamName
      end
    end
  end
end
