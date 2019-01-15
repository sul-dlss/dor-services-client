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
      let(:object_id) { 'druid:123' }

      context 'with a nil object_id value' do
        let(:object_id) { nil }

        it 'raises an ArgumentError' do
          expect { described_class.object(object_id) }.to raise_error(ArgumentError)
        end
      end

      it 'returns an instance of Client::Object' do
        expect(described_class.object(object_id)).to be_instance_of Dor::Services::Client::Object
      end

      it 'returns the memoized instance when called again' do
        expect(described_class.object(object_id)).to eq described_class.object(object_id)
      end

      it 'refreshes the memoized instance when called with a different identifier'  do
        expect(described_class.object(object_id)).not_to eq described_class.object('druid:1234')
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

  context 'when passed a username and password' do
    before do
      described_class.configure(url: 'https://dor-services.example.com',
                                username: username,
                                password: password)
    end

    let(:username) { 'foo' }
    let(:password) { 'bar' }

    it 'sets the Authorization header on the instance connection' do
      expect(described_class.instance.send(:connection).headers).to include(
        'Authorization' => 'Basic Zm9vOmJhcg=='
      )
    end
  end
end
