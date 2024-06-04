# frozen_string_literal: true

module Dor
  module Services
    class Client
      # A tag that indicates the item or collection should be released.
      class ReleaseTag < Dry::Struct
        transform_keys(&:to_sym)
        schema schema.strict
        # Who did this release
        # example: petucket
        attribute? :who, Types::Strict::String
        # What is being released. This item or the whole collection.
        # example: self
        attribute :what, Types::Strict::String.enum('self', 'collection')
        # When did this action happen
        attribute? :date, Types::Params::DateTime
        # What platform is it released to
        # example: Searchworks
        attribute? :to, Types::Strict::String
        attribute :release, Types::Strict::Bool.default(false)
      end
    end
  end
end
