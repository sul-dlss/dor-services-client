# frozen_string_literal: true

module Dor
  module Services
    class Client
      # A Cocina-like object that wraps an invalid Cocina object
      class InvalidCocina < Hashie::Mash
        include Hashie::Extensions::Mash::SymbolizeKeys

        disable_warnings :size
      end
    end
  end
end
