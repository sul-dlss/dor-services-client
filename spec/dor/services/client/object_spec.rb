# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Object do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:pid) { 'druid:1234' }

  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: pid) }

  describe '#object_identifier' do
    it 'returns the injected pid' do
      expect(client.object_identifier).to eq pid
    end
  end

  describe '#files' do
    it 'returns an instance of Client::Files' do
      expect(client.files).to be_instance_of Dor::Services::Client::Files
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

  describe '#release_tags' do
    it 'returns an instance of Client::ReleaseTags' do
      expect(client.release_tags).to be_instance_of Dor::Services::Client::ReleaseTags
    end
  end

  describe '#administrative_tags' do
    it 'returns an instance of Client::AdministrativeTags' do
      expect(client.administrative_tags).to be_instance_of Dor::Services::Client::AdministrativeTags
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

  describe '#embargo' do
    it 'returns an instance of Client::Embargo' do
      expect(client.embargo).to be_instance_of Dor::Services::Client::Embargo
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
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234')
        .to_return(status: status,
                   body: json)
    end

    context 'when API request succeeds with DRO' do
      let(:json) do
        <<~JSON
          {
            "externalIdentifier":"druid:12343234",
            "type":"http://cocina.sul.stanford.edu/models/book.jsonld",
            "label":"my item",
            "version":1,
            "description":{
              "title": [
                { "titleFull": "hey!", "primary":true }
              ]
            }
          }
        JSON
      end

      let(:status) { 200 }

      it 'returns the cocina model' do
        expect(model.externalIdentifier).to eq 'druid:12343234'
      end
    end

    context 'when API request succeeds with Collection' do
      let(:json) do
        <<~JSON
          {
            "externalIdentifier":"druid:12343234",
            "type":"http://cocina.sul.stanford.edu/models/collection.jsonld",
            "label":"my item",
            "version":1,
            "description":{
              "title": [
                { "titleFull": "hey!", "primary":true }
              ]
            }
          }
        JSON
      end

      let(:status) { 200 }

      it 'returns the cocina model' do
        expect(model.externalIdentifier).to eq 'druid:12343234'
      end
    end
  end

  describe '#publish' do
    subject(:request) { client.publish(workflow: 'accessionWF') }
    subject(:no_wf_request) { client.publish }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/publish?workflow=accessionWF')
        .to_return(status: status, headers: { 'Location' => 'https://dor-services.example.com/v1/background_job_results/123' })
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/publish')
        .to_return(status: status, headers: { 'Location' => 'https://dor-services.example.com/v1/background_job_results/123' })
    end

    context 'when API request succeeds' do
      let(:status) { 200 }

      it 'returns true' do
        expect(request).to eq 'https://dor-services.example.com/v1/background_job_results/123'
      end

      it 'returns true' do
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

  describe '#start_accession' do
    subject(:request) { client.start_accession }

    context 'with no params' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/start_accession')
          .to_return(status: status)
      end

      context 'when API request succeeds' do
        let(:status) { 201 }

        it 'returns true' do
          expect(request).to eq true
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

    context 'with params' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/start_accession?workflow=accessionWF&opening_user_name=dude')
          .to_return(status: status)
      end

      context 'when API request succeeds' do
        let(:status) { 201 }
        let(:params) { { opening_user_name: 'dude', workflow: 'accessionWF' } }

        it 'returns true' do
          expect(client.start_accession(params)).to eq true
        end
      end
    end
  end

  describe '#preserve' do
    subject(:request) { client.preserve }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/preserve')
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
    subject(:request) { client.shelve }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/shelve')
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
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/update_marc_record')
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

  describe '#refresh_metadata' do
    subject(:request) { client.refresh_metadata }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/refresh_metadata')
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

  describe '#notify_goobi' do
    subject(:request) { client.notify_goobi }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/notify_goobi')
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
