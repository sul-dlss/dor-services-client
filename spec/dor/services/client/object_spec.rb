# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Object do
  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: pid) }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:pid) { 'druid:bc123df4567' }

  describe '#object_identifier' do
    it 'returns the injected pid' do
      expect(client.object_identifier).to eq pid
    end
  end

  describe '#collections' do
    let(:collections) { instance_double(Dor::Services::Client::Collections, collections: true) }

    before do
      allow(Dor::Services::Client::Collections).to receive(:new).and_return(collections)
    end

    it 'delegates to the Client::Collections' do
      client.collections
      expect(collections).to have_received(:collections)
    end
  end

  describe '#members' do
    let(:members) { instance_double(Dor::Services::Client::Members, members: true) }

    before do
      allow(Dor::Services::Client::Members).to receive(:new).and_return(members)
    end

    it 'delegates to the Client::Members' do
      client.members
      expect(members).to have_received(:members)
    end
  end

  describe '#administrative_tags' do
    it 'returns an instance of Client::AdministrativeTags' do
      expect(client.administrative_tags).to be_instance_of Dor::Services::Client::AdministrativeTags
    end
  end

  describe '#accession' do
    it 'returns an instance of Client::Accession' do
      expect(client.accession).to be_instance_of Dor::Services::Client::Accession
    end
  end

  describe '#metadata' do
    it 'returns an instance of Client::Metadata' do
      expect(client.metadata).to be_instance_of Dor::Services::Client::Metadata
    end
  end

  describe '#workspace' do
    it 'returns an instance of Client::Workspace' do
      expect(client.workspace).to be_instance_of Dor::Services::Client::Workspace
    end
  end

  describe '#version' do
    it 'returns an instance of Client::ObjectVersion' do
      expect(client.version).to be_instance_of Dor::Services::Client::ObjectVersion
    end
  end

  describe '#events' do
    it 'returns an instance of Client::Events' do
      expect(client.events).to be_instance_of Dor::Services::Client::Events
    end
  end

  describe '#find' do
    subject(:model) { client.find }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:bc123df4567')
        .to_return(status: status,
                   body: json)
    end

    context 'when API request succeeds with DRO' do
      let(:json) do
        <<~JSON
          {
            "externalIdentifier":"druid:bc123df4567",
            "type":"#{Cocina::Models::ObjectType.book}",
            "label":"my item",
            "version":1,
            "administrative":{
              "hasAdminPolicy":"druid:fv123df4567"
            },
            "description":{
              "purl":"https://purl.stanford.edu/bc123df4567",
              "title": [
                { "value": "hey!", "type": "primary" }
              ]
            },
            "access":{},
            "identification":{"sourceId":"sul:123"},
            "structural":{}
          }
        JSON
      end

      let(:status) { 200 }

      it 'returns the cocina model' do
        expect(model.externalIdentifier).to eq 'druid:bc123df4567'
      end
    end

    context 'when API request succeeds with Collection' do
      let(:json) do
        <<~JSON
          {
            "externalIdentifier":"druid:bc123df4567",
            "type":"#{Cocina::Models::ObjectType.collection}",
            "label":"my item",
            "version":1,
            "description":{
              "purl":"https://purl.stanford.edu/bc123df4567",
              "title": [
                { "value": "hey!", "type": "primary" }
              ]
            },
            "access":{},
            "administrative":{
              "hasAdminPolicy":"druid:fv123df4567"
            },
            "identification":{"sourceId":"sul:123"}
          }
        JSON
      end

      let(:status) { 200 }

      it 'returns the cocina model' do
        expect(model.externalIdentifier).to eq 'druid:bc123df4567'
      end
    end
  end

  describe '#find_with_metadata' do
    subject(:response) { client.find_with_metadata }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:bc123df4567')
        .to_return(status: status,
                   headers: {
                     'Last-Modified' => 'Wed, 03 Mar 2021 18:58:00 GMT',
                     'X-Created-At' => 'Wed, 01 Jan 2021 12:58:00 GMT',
                     'X-Served-By' => 'Awesome webserver'
                   },
                   body: json)
    end

    context 'when API request succeeds with DRO' do
      let(:json) do
        <<~JSON
          {
            "externalIdentifier":"druid:bc123df4567",
            "type":"#{Cocina::Models::ObjectType.book}",
            "label":"my item",
            "version":1,
            "administrative":{
              "hasAdminPolicy":"druid:fv123df4567"
            },
            "description":{
              "purl":"https://purl.stanford.edu/bc123df4567",
              "title": [
                { "value": "hey!", "type": "primary" }
              ]
            },
            "access":{},
            "identification":{"sourceId":"sul:123"},
            "structural":{}
          }
        JSON
      end

      let(:status) { 200 }

      # rubocop:disable RSpec/ExampleLength
      it 'returns the cocina model' do
        expect(response.first.externalIdentifier).to eq 'druid:bc123df4567'
        metadata = response[1]
        expect(metadata.updated_at).to eq('Wed, 03 Mar 2021 18:58:00 GMT')
        expect(metadata.created_at).to eq('Wed, 01 Jan 2021 12:58:00 GMT')
        allow(Deprecation).to receive(:warn)
        expect(metadata['Last-Modified']).to eq('Wed, 03 Mar 2021 18:58:00 GMT')
        expect(metadata['X-Created-At']).to eq('Wed, 01 Jan 2021 12:58:00 GMT')
        expect { metadata['X-Powered-By'] }.to raise_error(KeyError)
      end
      # rubocop:enable RSpec/ExampleLength
    end
  end

  describe '#update' do
    subject(:model) { client.update(params: dro) }

    let(:dro) { Cocina::Models::DRO.new(JSON.parse(json)) }

    before do
      stub_request(:patch, 'https://dor-services.example.com/v1/objects/druid:bc123df4567')
        .with(
          body: dro.to_json,
          headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
        )
        .to_return(status: status,
                   body: json)
    end

    context 'when API request succeeds with DRO' do
      let(:json) do
        <<~JSON
          {
            "externalIdentifier":"druid:bc123df4567",
            "type":"#{Cocina::Models::ObjectType.book}",
            "label":"my item",
            "version":1,
            "administrative":{
              "hasAdminPolicy":"druid:fv123df4567"
            },
            "description":{
              "purl":"https://purl.stanford.edu/bc123df4567",
              "title": [
                { "value": "hey!", "type": "primary" }
              ]
            },
            "access":{ "view": "dark", "download": "none" },
            "identification":{"sourceId":"sul:123"},
            "structural":{}
          }
        JSON
      end

      let(:status) { 200 }

      it 'returns the cocina model' do
        expect(model.externalIdentifier).to eq 'druid:bc123df4567'
      end
    end
  end

  describe '#publish' do
    subject(:request) { client.publish(workflow: 'accessionWF', lane_id: 'low') }

    subject(:no_wf_request) { client.publish }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/publish?workflow=accessionWF&lane-id=low')
        .to_return(status: status, headers: { 'Location' => 'https://dor-services.example.com/v1/background_job_results/123' })
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/publish')
        .to_return(status: status, headers: { 'Location' => 'https://dor-services.example.com/v1/background_job_results/123' })
    end

    context 'when API request succeeds' do
      let(:status) { 200 }

      it 'returns a url' do
        expect(request).to eq 'https://dor-services.example.com/v1/background_job_results/123'
      end

      it 'returns a url' do
        expect(no_wf_request).to eq 'https://dor-services.example.com/v1/background_job_results/123'
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse,
                                          "not found: 404 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end

      it 'raises a NotFoundResponse exception' do
        expect { no_wf_request }.to raise_error(Dor::Services::Client::NotFoundResponse,
                                                "not found: 404 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end

    context 'when API request fails' do
      let(:status) { [409, 'conflict'] }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "conflict: 409 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end
  end

  describe '#unpublish' do
    subject(:request) { client.unpublish }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/unpublish')
        .to_return(status: status, headers: { 'Location' => 'https://dor-services.example.com/v1/background_job_results/123' })
    end

    context 'when API request succeeds' do
      let(:status) { 200 }

      it 'returns a url' do
        expect(request).to eq 'https://dor-services.example.com/v1/background_job_results/123'
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse,
                                          "not found: 404 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end

    context 'when API request fails' do
      let(:status) { [409, 'conflict'] }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "conflict: 409 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end
  end

  describe '#preserve' do
    subject(:request) { client.preserve(lane_id: 'low') }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/preserve?lane-id=low')
        .to_return(status: status, headers: { 'Location' => 'https://dor-services.example.com/v1/background_job_results/123' })
    end

    context 'when API request succeeds' do
      let(:status) { 200 }

      it 'returns true' do
        expect(request).to eq 'https://dor-services.example.com/v1/background_job_results/123'
      end
    end

    context 'when API request fails' do
      let(:status) { [500, 'internal server error'] }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "internal server error: 500 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end
  end

  describe '#shelve' do
    subject(:request) { client.shelve(lane_id: 'low') }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/shelve?lane-id=low')
        .to_return(status: status, headers: { 'Location' => 'https://dor-services.example.com/v1/background_job_results/123' })
    end

    context 'when API request succeeds' do
      let(:status) { 204 }

      it 'returns true' do
        expect(request).to eq 'https://dor-services.example.com/v1/background_job_results/123'
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse,
                                          "not found: 404 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end

    context 'when API request fails' do
      let(:status) { [422, 'unprocessable entity'] }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "unprocessable entity: 422 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end
  end

  describe '#update_marc_record' do
    subject(:request) { client.update_marc_record }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/update_marc_record')
        .to_return(status: status)
    end

    context 'when API request succeeds' do
      let(:status) { 201 }

      it 'returns true' do
        expect(request).to be true
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse,
                                          "not found: 404 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end

    context 'when API request fails' do
      let(:status) { [409, 'conflict'] }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "conflict: 409 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end
  end

  describe '#update_doi_metadata' do
    subject(:request) { client.update_doi_metadata }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/update_doi_metadata')
        .to_return(status: status)
    end

    context 'when API request succeeds' do
      let(:status) { 202 }

      it 'returns true' do
        expect(request).to be true
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse,
                                          "not found: 404 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end
  end

  describe '#refresh_descriptive_metadata_from_ils' do
    subject(:request) { client.refresh_descriptive_metadata_from_ils }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/refresh_metadata')
        .to_return(status: status)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }

      it 'returns true' do
        expect(request).to be true
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse,
                                          "not found: 404 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end

    context 'when API request fails' do
      let(:status) { [401, 'unauthorized'] }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "unauthorized: 401 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end
  end

  describe '#apply_admin_policy_defaults' do
    subject(:request) { client.apply_admin_policy_defaults }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/apply_admin_policy_defaults')
        .to_return(status: status)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }

      it 'returns true' do
        expect(request).to be true
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse,
                                          "not found: 404 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end

    context 'when API request fails' do
      let(:status) { [401, 'unauthorized'] }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "unauthorized: 401 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end
  end

  describe '#destroy' do
    subject(:request) { client.destroy }

    context 'when API request succeeds' do
      before do
        stub_request(:delete, 'https://dor-services.example.com/v1/objects/druid:bc123df4567')
          .to_return(status: 204)
      end

      it 'when API request succeeds' do
        expect(request).to be true
      end
    end

    context 'when API request fails because of not found' do
      before do
        stub_request(:delete, 'https://dor-services.example.com/v1/objects/druid:bc123df4567')
          .to_return(status: [404, 'object not found'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse,
                                          "object not found: 404 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY}) for druid:bc123df4567")
      end
    end

    context 'when API request fails due to unexpected response' do
      before do
        stub_request(:delete, 'https://dor-services.example.com/v1/objects/druid:bc123df4567')
          .to_return(status: [500, 'something is amiss'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "something is amiss: 500 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY}) for druid:bc123df4567")
      end
    end
  end

  describe '#notify_goobi' do
    subject(:request) { client.notify_goobi }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/notify_goobi')
        .to_return(status: status)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }

      it 'returns true' do
        expect(request).to be true
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse,
                                          "not found: 404 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end

    context 'when API request fails' do
      let(:status) { [401, 'unauthorized'] }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "unauthorized: 401 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end
  end
end
