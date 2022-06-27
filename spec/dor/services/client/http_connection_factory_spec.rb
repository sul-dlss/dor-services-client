# frozen_string_literal: true

RSpec.describe Dor::Services::Client::HttpConnectionFactory do
  describe '#connection' do
    context 'when configured' do
      subject(:factory) { described_class.new(url: 'https://dor-services.example.com', token: '123', enable_get_retries: false) }

      it 'returns connection' do
        expect(factory.send(:connection)).to be_a(Dor::Services::Client::ConnectionWrapper)
      end
    end

    context 'when not configured' do
      subject(:factory) { described_class.new(url: nil, token: nil, enable_get_retries: nil) }

      it 'raises' do
        expect { factory.send(:connection) }.to raise_error(Dor::Services::Client::Error, 'url has not yet been configured')
      end
    end
  end

  describe '#build_connection' do
    subject(:factory) { described_class.new(url: 'https://dor-services.example.com', token: '123', enable_get_retries: true) }

    it 'sets the token on the connection using the default authorization header' do
      expect(factory.send(:build_connection).headers).to include(
        described_class::TOKEN_HEADER => 'Bearer 123',
        'User-Agent' => /dor-services-client \d+\.\d+\.\d+/
      )
    end

    it 'does not enable retries' do
      expect(factory.send(:build_connection).builder.handlers).not_to include(Faraday::Retry::Middleware)
    end

    context 'when with retries' do
      it 'enables retries' do
        expect(factory.send(:build_connection, with_retries: true).builder.handlers).to include(Faraday::Retry::Middleware)
      end
    end
  end
end
