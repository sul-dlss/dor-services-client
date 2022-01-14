# frozen_string_literal: true

RSpec.describe Dor::Services::Client::VersionedService do
  subject(:client) { subclass.new(connection: connection, version: 'v1') }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:subclass) do
    Class.new(described_class)
  end
  let(:connection) { Dor::Services::Client.instance.send(:connection) }

  describe '#async_result' do
    it 'creates an instance of AsyncResult' do
      expect(client.async_result(url: 'foobar')).to be_a(Dor::Services::Client::AsyncResult)
    end
  end
end
