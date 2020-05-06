# frozen_string_literal: true

RSpec.describe Dor::Services::Client::ConnectionWrapper do
  subject(:connection_wrapper) { described_class.new(connection: connection, get_connection: get_connection) }
  let(:connection) { instance_double(Faraday::Connection, post: true, put: true, patch: true, delete: true) }

  let(:get_connection) { instance_double(Faraday::Connection, get: true) }

  describe '.get' do
    before do
      connection_wrapper.get
    end
    it 'invokes get_connection' do
      expect(get_connection).to have_received(:get)
    end
  end

  describe '.post' do
    before do
      connection_wrapper.post
    end
    it 'invokes connection' do
      expect(connection).to have_received(:post)
    end
  end

  describe '.put' do
    before do
      connection_wrapper.put
    end
    it 'invokes connection' do
      expect(connection).to have_received(:put)
    end
  end

  describe '.patch' do
    before do
      connection_wrapper.patch
    end
    it 'invokes connection' do
      expect(connection).to have_received(:patch)
    end
  end

  describe '.delete' do
    before do
      connection_wrapper.delete
    end
    it 'invokes connection' do
      expect(connection).to have_received(:delete)
    end
  end
end
