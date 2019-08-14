# frozen_string_literal: true

RSpec.describe Dor::Services::Client::ObjectVersion do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:pid) { 'druid:1234' }

  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: pid) }

  describe '#current_version' do
    subject(:request) { client.current }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/versions/current')
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) { '2' }

      it 'returns the value' do
        expect(request).to eq '2'
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }
      let(:body) { '' }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse, 'not found: 404 ()')
      end
    end

    context 'when API request fails' do
      let(:status) { [401, 'unauthorized'] }
      let(:body) { '' }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse, 'unauthorized: 401 ()')
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

  describe '#open_new_version' do
    let(:params) { {} }

    subject(:request) { client.open(**params) }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/versions')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: status, body: body)
    end

    context 'with additional params' do
      let(:status) { 200 }
      let(:body) { '2' }
      let(:params) { { foo: 'bar' } }

      before do
        # The `.with(body: ...)` is what tests that params are passed through as json
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/versions')
          .with(headers: { 'Content-Type' => 'application/json' },
                body: params.to_json)
          .to_return(status: status, body: body)
      end

      it 'returns version string' do
        expect(request).to eq '2'
      end
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) { '2' }

      it 'returns version string' do
        expect(request).to eq '2'
      end
    end

    context 'when API request responds with blank text' do
      let(:status) { 200 }
      let(:body) { '' }

      it 'raises a MalformedResponse error' do
        expect { request }.to raise_error(Dor::Services::Client::MalformedResponse,
                                          'Version of druid:1234 is empty')
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }
      let(:body) { '' }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse, 'not found: 404 ()')
      end
    end

    context 'when API request fails' do
      let(:status) { [500, 'internal server error'] }
      let(:body) { 'broken' }

      it 'raises an UnexpectedResponse error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          'internal server error: 500 (broken)')
      end
    end
  end

  describe '#close_version' do
    let(:params) { {} }

    subject(:request) { client.close(**params) }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/versions/current/close')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: status, body: body)
    end

    context 'with additional params' do
      let(:status) { 200 }
      let(:body) { 'version 2 closed' }
      let(:params) { { foo: 'bar' } }

      before do
        # The `.with(body: ...)` is what tests that params are passed through as json
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/versions/current/close')
          .with(headers: { 'Content-Type' => 'application/json' },
                body: params.to_json)
          .to_return(status: status, body: body)
      end

      it 'returns confirmation message' do
        expect(request).to eq body
      end
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) { 'version 2 closed' }

      it 'returns confirmation message' do
        expect(request).to eq body
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }
      let(:body) { '' }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse, 'not found: 404 ()')
      end
    end

    context 'when API request fails' do
      let(:status) { [500, 'internal server error'] }
      let(:body) { 'broken' }

      it 'raises an UnexpectedResponse error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          'internal server error: 500 (broken)')
      end
    end
  end

  describe '#openeable?' do
    let(:status) { 200 }
    let(:body) { 'true' }

    subject(:request) { client.openeable?(assume_accessioned: true) }

    before do
      # TODO: correct the typo below once
      #       https://github.com/sul-dlss/dor-services-app/issues/322 is
      #       merged and all running DSA instances have been deployed
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/versions/openeable?assume_accessioned=true')
        .to_return(status: status, body: body)
      allow(Deprecation).to receive(:warn)
    end

    it 'delegates to the non-deprecated form' do
      expect(request).to be true
      expect(Deprecation).to have_received(:warn)
    end
  end

  describe '#openable?' do
    let(:params) { {} }

    subject(:request) { client.openable?(assume_accessioned: true) }

    before do
      # TODO: correct the typo below once
      #       https://github.com/sul-dlss/dor-services-app/issues/322 is
      #       merged and all running DSA instances have been deployed
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/versions/openeable?assume_accessioned=true')
        .to_return(status: status, body: body)
    end

    context 'when API returns true' do
      let(:status) { 200 }
      let(:body) { 'true' }

      it 'returns true' do
        expect(request).to be true
      end
    end

    context 'when API returns false' do
      let(:status) { 200 }
      let(:body) { 'false' }

      it 'returns true' do
        expect(request).to be false
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }
      let(:body) { '' }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse, 'not found: 404 ()')
      end
    end

    context 'when API request fails' do
      let(:status) { [500, 'internal server error'] }
      let(:body) { 'broken' }

      it 'raises an UnexpectedResponse error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          'internal server error: 500 (broken)')
      end
    end
  end
end
