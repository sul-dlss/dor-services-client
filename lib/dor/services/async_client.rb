# frozen_string_literal: true

module Dor
  module Services
    class AsyncClient
      include Singleton

      # @param object_identifier [String] the pid for the object
      # @raise [ArgumentError] when `object_identifier` is `nil`
      # @return [Dor::Services::AsyncClient::Object] an instance of the `Client::Object` class
      def object(object_identifier)
        raise ArgumentError, '`object_identifier` argument cannot be `nil` in call to `#object(object_identifier)' if object_identifier.nil?

        # Return memoized object instance if object identifier value is the same
        # This allows us to test the client more easily in downstream codebases,
        # opening up stubbing without requiring `any_instance_of`
        return @object if @object&.object_identifier == object_identifier

        @object = Object.new(connection: channel, object_identifier: object_identifier)
      end

      class << self
        def configure(hostname:, vhost:, username:, password:)
          instance.hostname = hostname
          instance.vhost = vhost
          instance.username = username
          instance.password = password

          # Force connection to be re-established when `.configure` is called
          instance.channel = nil

          self
        end

        delegate :object, to: :instance
      end

      attr_writer :hostname, :vhost, :username, :password, :hostname

      private

      attr_reader :vhost, :username, :password

      def hostname
        @hostname || raise(Error, 'hostname has not yet been configured')
      end

      def channel
        @channel ||= begin
          connection = Bunny.new(hostname: hostname,
                                 vhost: vhost,
                                 username: username,
                                 password: password).tap(&:start)
          connection.create_channel
        end
      end
    end
  end
end
