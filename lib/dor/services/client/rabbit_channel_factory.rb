# frozen_string_literal: true

module Dor
  module Services
    class Client
      # Factory for creating Rabbit channel.
      # Note that that channel is lazily created.
      class RabbitChannelFactory
        def initialize(hostname:, vhost:, username:, password:)
          @hostname = hostname
          @vhost = vhost
          @username = username
          @password = password
        end

        delegate :topic, to: :channel

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
end
