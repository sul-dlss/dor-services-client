# frozen_string_literal: true

require 'active_support/core_ext/time'

RSpec.describe Dor::Services::Client::Metadata do
  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: pid) }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:pid) { 'druid:1234' }

  describe '#dublin_core' do
    subject(:response) { client.dublin_core }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/metadata/dublin_core')
        .to_return(status: status, body: body)
    end

    context 'when the object is found' do
      let(:status) { 200 }
      let(:body) { '<dc />' }

      it { is_expected.to eq '<dc />' }
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

  describe '#public_xml' do
    subject(:response) { client.public_xml }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/metadata/public_xml')
        .to_return(status: status, body: body)
    end

    context 'when the object is found' do
      let(:status) { 200 }
      let(:body) do
        <<~XML
          <publicObject id="druid:1234" published="2021-04-23T19:43:06Z" publishVersion="dor-services/9.6.2">
            <identityMetadata/>
            <rightsMetadata>
              <access type="discover">
                <machine>
                  <none/>
                </machine>
              </access>
              <access type="read">
                <machine>
                  <none/>
                </machine>
              </access>
              <use>
                <human type="useAndReproduction"/>
                <human type="creativeCommons"/>
                <machine type="creativeCommons" uri=""/>
                <human type="openDataCommons"/>
                <machine type="openDataCommons" uri=""/>
              </use>
              <copyright>
                <human/>
              </copyright>
            </rightsMetadata>
          </publicObject>
        XML
      end

      it { is_expected.to eq body }
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

  describe '#descriptive' do
    subject(:response) { client.descriptive }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/metadata/descriptive')
        .to_return(status: status, body: body)
    end

    context 'when the object is found' do
      let(:status) { 200 }
      let(:body) { '<publicObject />' }

      it { is_expected.to eq '<publicObject />' }
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

  describe '#mods' do
    subject(:response) { client.mods }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/metadata/mods')
        .to_return(status: status, body: body)
    end

    context 'when the object is found' do
      let(:status) { 200 }
      let(:body) { '<mods />' }

      it { is_expected.to eq '<mods />' }
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

  describe '#legacy_update' do
    context 'when many datastreams' do
      let(:params) do
        {
          descriptive: { updated: Time.find_zone('UTC').parse('2020-01-05'), content: '<descMetadata/>' },
          identity: { updated: Time.find_zone('UTC').parse('2020-01-05'), content: '<identityMetadata/>' },
          geo: { updated: Time.find_zone('UTC').parse('2020-01-05'), content: '<geoMetadata/>' }
        }
      end

      before do
        stub_request(:patch, 'https://dor-services.example.com/v1/objects/druid:1234/metadata/legacy')
          .with(
            body: '{"descriptive":{"updated":"2020-01-05T00:00:00.000Z","content":"\\u003cdescMetadata/\\u003e"},' \
                  '"geo":{"updated":"2020-01-05T00:00:00.000Z","content":"\\u003cgeoMetadata/\\u003e"},' \
                  '"identity":{"updated":"2020-01-05T00:00:00.000Z","content":"\\u003cidentityMetadata/\\u003e"}}',
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(status: status)
      end

      context 'when API request succeeds' do
        let(:status) { 204 }

        it 'posts params as json' do
          # byebug
          expect(client.legacy_update(params)).to be_nil
        end
      end

      context 'when API request fails' do
        let(:status) { [404, 'not found'] }

        it 'raises an error' do
          expect { client.legacy_update(params) }.to(
            raise_error(Dor::Services::Client::NotFoundResponse,
                        "not found: 404 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY}) for druid:1234")
          )
        end
      end
    end

    context 'with provenance' do
      let(:params) { { provenance: { updated: Time.find_zone('UTC').parse('2020-01-05'), content: '<provenanceMetadata />' } } }

      before do
        stub_request(:patch, 'https://dor-services.example.com/v1/objects/druid:1234/metadata/legacy')
          .with(
            body: '{"provenance":{"updated":"2020-01-05T00:00:00.000Z","content":"\\u003cprovenanceMetadata /\u003e"}}',
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(status: status)
      end

      context 'when API request succeeds' do
        let(:status) { 204 }

        it 'posts params as json' do
          expect(client.legacy_update(params)).to be_nil
        end
      end

      context 'when API request fails' do
        let(:status) { [404, 'not found'] }

        it 'raises an error' do
          expect { client.legacy_update(params) }.to(
            raise_error(Dor::Services::Client::NotFoundResponse,
                        "not found: 404 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY}) for druid:1234")
          )
        end
      end
    end
  end

  describe '#datastreams' do
    subject(:request) { client.datastreams }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/metadata/datastreams')
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) do
        <<~JSON
          [
            {"label":"descriptive metadata","dsid":"descMetadata","pid":"druid:1234","size":"14","mimeType":"application/xml","versionId":"v0"},
            {"label":"content metadata","dsid":"contentMetadata","pid":"druid:1234","size":"22","mimeType":"application/xml","versionId":"v5"}
          ]
        JSON
      end

      it 'returns the list of versions' do
        expect(request).to eq [
          described_class::Datastream.new(label: 'descriptive metadata', dsid: 'descMetadata', pid: 'druid:1234', size: '14', versionId: 'v0',
                                          mimeType: 'application/xml'),
          described_class::Datastream.new(label: 'content metadata', dsid: 'contentMetadata', pid: 'druid:1234', size: '22', versionId: 'v5',
                                          mimeType: 'application/xml')
        ]
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }
      let(:body) { '' }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end

    context 'when API request fails' do
      let(:status) { [401, 'unauthorized'] }
      let(:body) { '' }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnauthorizedResponse)
      end
    end

    context 'when connection fails' do
      before do
        allow_any_instance_of(Faraday::Adapter::NetHttp).to receive(:call).and_raise(Faraday::ConnectionFailed.new('end of file reached'))
      end

      let(:status) { 555 }
      let(:body) { '' }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::ConnectionFailed, 'unable to reach dor-services-app')
      end
    end
  end

  describe '#datastream' do
    subject(:response) { client.datastream('descMetadata') }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/metadata/datastreams/descMetadata')
        .to_return(status: status, body: body)
    end

    context 'when the object is found' do
      let(:status) { 200 }
      let(:body) { '<mods />' }

      it { is_expected.to eq '<mods />' }
    end

    context 'when the object is not found' do
      let(:status) { 404 }
      let(:body) { '' }

      it 'raises an error' do
        expect { response }.to raise_error Dor::Services::Client::NotFoundResponse
      end
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
