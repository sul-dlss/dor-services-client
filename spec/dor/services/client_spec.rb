# frozen_string_literal: true

RSpec.describe Dor::Services::Client do
  it 'has a version number' do
    expect(Dor::Services::Client::VERSION).not_to be nil
  end

  context 'once configured' do
    before do
      described_class.configure(url: 'https://dor-services.example.com')
    end

    describe '.object' do
      let(:object_identifier) { 'druid:123' }

      context 'with a nil object_identifier value' do
        let(:object_identifier) { nil }

        it 'raises an ArgumentError' do
          expect { described_class.object(object_identifier) }.to raise_error(ArgumentError)
        end
      end

      it 'returns an instance of Client::Object' do
        expect(described_class.object(object_identifier)).to be_instance_of Dor::Services::Client::Object
      end

      it 'returns the memoized instance when called again' do
        expect(described_class.object(object_identifier)).to eq described_class.object(object_identifier)
      end

      it 'refreshes the memoized instance when called with a different identifier' do
        expect(described_class.object(object_identifier)).not_to eq described_class.object('druid:1234')
      end
    end

    describe '.objects' do
      it 'returns an instance of Client::Objects' do
        expect(described_class.objects).to be_instance_of Dor::Services::Client::Objects
      end

      it 'returns the memoized instance when called again' do
        expect(described_class.objects).to eq described_class.objects
      end
    end
  end

  describe '#configure' do
    subject(:client) { described_class.configure(url: 'https://dor-services.example.com') }

    it 'returns Client class' do
      expect(client).to eq Dor::Services::Client
    end
  end

  context 'when passed a token and token_header' do
    before do
      described_class.configure(url: 'https://dor-services.example.com',
                                token_header: 'X-Auth',
                                token: '123')
    end

    it 'sets the token header on the connection' do
      expect(described_class.instance.send(:connection).headers).to include(
        'X-Auth' => 'Bearer 123',
        'User-Agent' => /dor-services-client \d+\.\d+\.\d+/
      )
    end
  end

  context 'when passed a token without a token_header' do
    before do
      described_class.configure(url: 'https://dor-services.example.com',
                                token: '123')
    end

    it 'sets the token on the connection and uses the default authorization header' do
      expect(described_class.instance.send(:connection).headers).to include(
        'Authorization' => 'Bearer 123',
        'User-Agent' => /dor-services-client \d+\.\d+\.\d+/
      )
    end
  end
end
