# frozen_string_literal: true

RSpec.describe Dor::Services::Client do
  it 'has a version number' do
    expect(Dor::Services::Client::VERSION).not_to be nil
  end

  subject(:client) { described_class.instance }

  context 'once configured' do
    before do
      described_class.configure(url: 'https://dor-services.example.com')
    end

    describe '.object' do
      it 'returns an instance of Client::Object' do
        expect(described_class.object('druid:123')).to be_instance_of Dor::Services::Client::Object
      end
    end

    describe '.objects' do
      it 'returns an instance of Client::Objects' do
        expect(described_class.objects).to be_instance_of Dor::Services::Client::Objects
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
