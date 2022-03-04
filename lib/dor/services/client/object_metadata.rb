# frozen_string_literal: true

require 'deprecation'

module Dor
  module Services
    class Client
      # An object representing metadata about the cocina object returned by the object show method
      class ObjectMetadata
        extend Deprecation

        attr_reader :created_at, :updated_at, :etag

        def initialize(created_at:, updated_at:, etag: nil)
          @created_at = created_at
          @updated_at = updated_at
          @etag = etag
        end

        def [](key)
          case key
          when 'Last-Modified'
            updated_at
          when 'X-Created-At'
            created_at
          else
            raise KeyError, 'Unknown key'
          end
        end
        deprecation_deprecate(:[] => 'Hash accessor is no longer used, use object accessor instead')
      end
    end
  end
end
