# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about searching AdministrativeTags
      class AdministrativeTagSearch < VersionedService
        def search(q:) # rubocop:disable Naming/MethodParameterName
          resp = connection.get do |req|
            req.url "#{api_version}/administrative_tags/search?q=#{q}"
          end

          # Since argo is using this as a proxy, no need to parse the response.
          return resp.body if resp.success?

          raise_exception_based_on_response!(resp)
        end
      end
    end
  end
end
