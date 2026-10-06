# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Events do
  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: pid) }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:pid) { 'druid:1234' }

  describe '#list' do
    subject(:response) { client.list(event_types: event_types, from: from, to: to) }

    let(:status) { 200 }
    let(:body) do
      '[{"event_type":"shelve_request_received","data":{"host":"http://example.com/"},"created_at":"2020-01-27T19:10:27.291Z"},' \
        '{"event_type":"shelve_request_received","data":{"host":"http://example.com/"},"created_at":"2020-01-30T16:10:28.771Z"}]'
    end
    let(:event_types) { nil }
    let(:from) { nil }
    let(:to) { nil }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/events')
        .to_return(status: status, body: body)
    end

    context 'when the object is found' do
      it 'returns the list' do
        expect(response.size).to eq 2
        expect(response.first.event_type).to eq 'shelve_request_received'
        expect(response.first.timestamp).to eq '2020-01-27T19:10:27.291Z'
      end
    end

    context 'when event types are specified' do
      let(:event_types) { %w[shelve_request_received update] }

      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/events?event_types[]=shelve_request_received&event_types[]=update')
          .to_return(status: status, body: body)
      end

      it 'returns the list' do
        expect(response.size).to eq 2
      end
    end

    context 'when from and to are specified as strings' do
      let(:from) { '2026-10-01' }
      let(:to) { '2026-10-02T12:00:00-07:00' }

      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/events')
          .with(query: { from: '2026-10-01', to: '2026-10-02T12:00:00-07:00' })
          .to_return(status: status, body: body)
      end

      it 'returns the list' do
        expect(response.size).to eq 2
      end
    end

    context 'when from and to are specified as a Date and a Time' do
      let(:from) { Date.new(2026, 10, 1) }
      let(:to) { Time.utc(2026, 10, 2, 12) }

      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/events')
          .with(query: { from: '2026-10-01', to: '2026-10-02T12:00:00Z' })
          .to_return(status: status, body: body)
      end

      it 'returns the list' do
        expect(response.size).to eq 2
      end
    end

    context 'when from is invalid' do
      let(:from) { 'yesterday' }
      let(:status) { [400, 'bad request'] }
      let(:body) { '{"errors":[{"title":"bad request","detail":"from must be an ISO 8601 date or date-time"}]}' }

      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/events?from=yesterday')
          .to_return(status: status, body: body)
      end

      it 'raises an error' do
        expect { response }.to raise_error(Dor::Services::Client::BadRequestError)
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

  describe '#create' do
    subject(:request) do
      client.create(type: 'publishing_complete', data: { target: 'SearchWorks', host: 'foo.example.edu', result: 'success!' })
    end

    context 'when API request succeeds' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/events')
          .to_return(status: 201)
      end

      it 'posts tags' do
        expect(request).to be true
      end
    end

    context 'when the event type is unknown' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/events')
          .to_return(status: [400, 'bad request'],
                     body: '{"errors":[{"title":"bad request","detail":"Validation failed: Event type is not included in the list"}]}')
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::BadRequestError)
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/events')
          .to_return(status: [500, 'something is amiss'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "something is amiss: 500 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY}) for druid:1234")
      end
    end
  end
end
