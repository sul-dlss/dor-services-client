# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Workflows do
  subject(:client) { described_class.new(connection: connection, version: 'v1') }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }

  describe '#templates' do
    before do
      stub_request(:get, 'https://dor-services.example.com/v1/workflow_templates')
        .with(
          headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
        )
        .to_return(status: status, body: body, headers: { 'Location' => 'https://dor-services.example.com/v1/background_job_results/123' })
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:templates) { %w[assemblyWF registrationWF] }
      let(:body) { templates.to_json }

      it 'returns templates' do
        expect(client.templates).to eq(templates)
      end
    end

    context 'when API request fails' do
      let(:status) { [500] }
      let(:body) { '{"errors":["error message here"]}' }

      it 'raises an error' do
        expect { client.templates }.to raise_error(Dor::Services::Client::UnexpectedResponse)
      end
    end
  end
end
