# frozen_string_literal: true

RSpec.describe Dor::Services::Client::ReleaseTags do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:pid) { 'druid:123' }

  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: pid) }

  describe '#list' do
    subject(:request) { client.list }

    context 'when API request succeeds' do
      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:123/release_tags')
          .to_return(status: 200, body: '{"SearchWorks":{"release":true}}')
      end

      it 'lists release tags' do
        expect(request).to eq(
          'SearchWorks' => {
            'release' => true
          }
        )
      end
    end

    context 'when API request fails because of not found' do
      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:123/release_tags')
          .to_return(status: [404, 'object not found'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse,
                                          "object not found: 404 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY}) for druid:123")
      end
    end

    context 'when API request fails due to unexpected response' do
      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:123/release_tags')
          .to_return(status: [500, 'something is amiss'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "something is amiss: 500 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY}) for druid:123")
      end
    end
  end

  describe '#create' do
    subject(:request) { client.create(release: true, to: 'searchworks', who: 'justin', what: 'foo') }

    context 'when API request succeeds' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:123/release_tags')
          .to_return(status: 201)
      end

      it 'posts tags' do
        expect(request).to be true
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:123/release_tags')
          .to_return(status: [500, 'something is amiss'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "something is amiss: 500 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY}) for druid:123")
      end
    end
  end
end
