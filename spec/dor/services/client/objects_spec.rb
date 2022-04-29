# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Objects do
  subject(:client) { described_class.new(connection: connection, version: 'v1') }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:request_dro) { Cocina::Models::RequestDRO.new(properties) }
  let(:properties) do
    {
      type: Cocina::Models::ObjectType.object,
      label: 'My object',
      version: 1,
      administrative: { hasAdminPolicy: 'druid:fv123df4567' },
      identification: { sourceId: 'sul:99999' },
      structural: {}
    }
  end
  let(:expected_request) { request_dro.to_json }
  let(:description_props) do
    {
      title: [{ value: 'Test DRO' }],
      purl: 'https://purl.stanford.edu/bc123df4567'
    }
  end

  describe '#register' do
    let(:status) { 201 }
    let(:body) do
      Cocina::Models::DRO.new(request_dro.to_h.merge(externalIdentifier: 'druid:bc123df4567',
                                                     access: {}, description: description_props)).to_json
    end
    let(:url) { 'https://dor-services.example.com/v1/objects' }

    before do
      stub_request(:post, url)
        .with(
          body: expected_request,
          headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
        )
        .to_return(status: status,
                   body: body,
                   headers: {
                     'Last-Modified' => 'Wed, 04 Mar 2021 18:58:00 GMT',
                     'X-Created-At' => 'Wed, 02 Jan 2021 12:58:00 GMT',
                     'X-Served-By' => 'Awesome webserver',
                     'ETag' => 'W/"e541d8cd98f00b204e9800998ecf8427f"'
                   })
    end

    context 'when API request succeeds with a cocina request_dro' do
      it 'posts params as json' do
        expect(client.register(params: request_dro)).to be_kind_of Cocina::Models::DROWithMetadata
      end
    end

    context 'when assigning DOI' do
      let(:url) { 'https://dor-services.example.com/v1/objects?assign_doi=true' }

      it 'posts with DOI param' do
        client.register(params: request_dro, assign_doi: true)
      end
    end

    context 'when API request fails' do
      context 'when Conflict (409) response' do
        let(:status) { [409, 'object already exists'] }
        let(:body) { nil }

        it 'raises ConflictResponse error' do
          expect { client.register(params: request_dro) }.to raise_error(Dor::Services::Client::ConflictResponse,
                                                                         'object already exists: 409 ' \
                                                                         "(#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
        end
      end

      context 'when Unauthorized (401) response' do
        let(:status) { [401, 'unauthorized'] }
        let(:body) { nil }

        it 'raises UnauthorizedResponse error' do
          expect { client.register(params: request_dro) }.to raise_error(Dor::Services::Client::UnauthorizedResponse)
        end
      end

      context 'when Bad Request (400) response' do
        let(:status) { [400, 'bad request'] }
        let(:body) { 'Bad Request: 400 ({"errors":[{"status":"400","title":some reason","detail":"blah di blah blah"}]})' }

        it 'raises BadRequestError error' do
          expect { client.register(params: request_dro) }.to raise_error(Dor::Services::Client::BadRequestError)
        end
      end
    end
  end
end
