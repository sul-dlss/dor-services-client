# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Object do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com')
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

  describe '#release_tags' do
    it 'returns an instance of Client::ReleaseTags' do
      expect(client.release_tags).to be_instance_of Dor::Services::Client::ReleaseTags
    end
  end

  describe '#sdr' do
    it 'returns an instance of Client::SDR' do
      expect(client.sdr).to be_instance_of Dor::Services::Client::SDR
    end
  end

  describe '#workflow' do
    it 'returns an instance of Client::Workflow' do
      expect(client.workflow).to be_instance_of Dor::Services::Client::Workflow
    end
  end

  describe '#workspace' do
    it 'returns an instance of Client::Workspace' do
      expect(client.workspace).to be_instance_of Dor::Services::Client::Workspace
    end
  end

  describe '#publish' do
    subject(:request) { client.publish }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/publish')
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
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse, 'not found: 404 ()')
      end
    end

    context 'when API request fails' do
      let(:status) { [409, 'conflict'] }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse, 'conflict: 409 ()')
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
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse, 'not found: 404 ()')
      end
    end

    context 'when API request fails' do
      let(:status) { [409, 'conflict'] }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse, 'conflict: 409 ()')
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
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse, 'not found: 404 ()')
      end
    end

    context 'when API request fails' do
      let(:status) { [401, 'unauthorized'] }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse, 'unauthorized: 401 ()')
      end
    end
  end

  describe '#current_version' do
    subject(:request) { client.current_version }

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
  end

  describe '#open_new_version' do
    let(:params) { {} }

    subject(:request) { client.open_new_version(**params) }

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

    subject(:request) { client.close_version(**params) }

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
end
