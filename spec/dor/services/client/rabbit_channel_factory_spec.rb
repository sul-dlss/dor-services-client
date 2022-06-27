# frozen_string_literal: true

RSpec.describe Dor::Services::Client::RabbitChannelFactory do
  describe '#connection' do
    context 'when configured' do
      subject(:factory) { described_class.new(hostname: 'localhost', vhost: '/', username: 'guest', password: 'guest') }

      let(:session) { instance_double(Bunny::Session, start: nil, create_channel: channel) }

      let(:channel) { instance_double(Bunny::Channel) }

      before do
        allow(Bunny).to receive(:new).and_return(session)
      end

      it 'returns connection' do
        expect(factory.send(:channel)).to be channel
      end
    end

    context 'when not configured' do
      subject(:factory) { described_class.new(hostname: nil, vhost: nil, username: nil, password: nil) }

      it 'raises' do
        expect { factory.send(:channel) }.to raise_error(Dor::Services::Client::Error, 'hostname has not yet been configured')
      end
    end
  end
end
