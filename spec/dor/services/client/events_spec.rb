# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Events do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:pid) { 'druid:1234' }

  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: pid) }

  describe '#list' do
    subject(:response) { client.list }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/events')
        .to_return(status: status, body: body)
    end

    context 'when the object is found' do
      let(:status) { 200 }
      let(:body) do
        '[{"event_type":"shelve_request_received","data":{"host":"http://example.com/"},"created_at":"2020-01-27T19:10:27.291Z"},' \
      '{"event_type":"shelve_request_received","data":{"host":"http://example.com/"},"created_at":"2020-01-30T16:10:28.771Z"}]'
      end

      it 'returns the list' do
        expect(response.size).to eq 2
        expect(response.first.event_type).to eq 'shelve_request_received'
        expect(response.first.timestamp).to eq '2020-01-27T19:10:27.291Z'
      end
    end

    context 'when the object is not found' do
      let(:status) { 404 }
      let(:body) { '' }

      it { is_expected.to be_nil }
    end

    context 'when there is a server error' do
      let(:status) { [500, 'internal server error'] }
      let(:body) { 'broken' }

      it 'raises an error' do
        expect { response }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                           'internal server error: 500 (broken) for druid:1234')
      end
    end
  end
end
