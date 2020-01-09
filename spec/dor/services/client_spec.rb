# frozen_string_literal: true

RSpec.describe Dor::Services::Client do
  it 'has a version number' do
    expect(Dor::Services::Client::VERSION).not_to be nil
  end

  context 'once configured' do
    before do
      described_class.configure(url: 'https://dor-services.example.com', token: '123')
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

    describe '.marcxml' do
      it 'returns an instance of Client::Marcxml' do
        expect(described_class.marcxml).to be_instance_of Dor::Services::Client::Marcxml
      end

      it 'returns the memoized instance when called again' do
        expect(described_class.marcxml).to eq described_class.marcxml
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

    describe '.virtual_objects' do
      it 'returns an instance of Client::VirtualObjects' do
        expect(described_class.virtual_objects).to be_instance_of Dor::Services::Client::VirtualObjects
      end

      it 'returns the memoized instance when called again' do
        expect(described_class.virtual_objects).to eq described_class.virtual_objects
      end
    end

    describe '.background_job_results' do
      it 'returns an instance of Client::BackgroundJobResults' do
        expect(described_class.background_job_results).to be_instance_of Dor::Services::Client::BackgroundJobResults
      end

      it 'returns the memoized instance when called again' do
        expect(described_class.background_job_results).to eq described_class.background_job_results
      end
    end
  end

  describe '#configure' do
    subject(:client) { described_class.configure(url: 'https://dor-services.example.com', token: '123') }

    it 'returns Client class' do
      expect(client).to eq Dor::Services::Client
    end

    it 'sets the token on the connection using the default authorization header' do
      expect(described_class.instance.send(:connection).headers).to include(
        described_class::TOKEN_HEADER => 'Bearer 123',
        'User-Agent' => /dor-services-client \d+\.\d+\.\d+/
      )
    end
  end
end
