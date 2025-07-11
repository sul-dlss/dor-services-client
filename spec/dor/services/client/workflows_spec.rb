# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Workflows do
  subject(:client) { described_class.new(connection: connection, version: 'v1') }

  let(:connection) { Dor::Services::Client.instance.send(:connection) }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  describe '#templates' do
    before do
      stub_request(:get, 'https://dor-services.example.com/v1/workflow_templates')
        .with(
          headers: { 'Accept' => 'application/json' }
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

  describe '#template' do
    let(:workflow_name) { 'accessionWF' }

    before do
      stub_request(:get, "https://dor-services.example.com/v1/workflow_templates/#{workflow_name}")
        .with(
          headers: { 'Accept' => 'application/json' }
        )
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:template) do
        {
          'processes' => [
            { 'name' => 'start-accession', 'label' => 'Start Accessioning' },
            { 'name' => 'stage', 'label' => 'Copies files (when present) from staging' },
            { 'name' => 'technical-metadata', 'label' => 'Creates the technical metadata by calling technical-metadata-service, only for item objects with files' },
            { 'name' => 'shelve', 'label' => 'Shelve content in Digital Stacks' },
            { 'name' => 'publish', 'label' => 'Sends metadata to PURL (but it may be updated by releaseWF)' },
            { 'name' => 'update-doi', 'label' => 'Update DOI Metadata' },
            { 'name' => 'update-orcid-work', 'label' => 'Update ORCID work' },
            { 'name' => 'sdr-ingest-transfer', 'label' => 'Initiate Ingest into Preservation' },
            { 'name' => 'sdr-ingest-received', 'label' => 'Signal from SDR that object has been received' },
            { 'name' => 'reset-workspace', 'label' => 'Reset workspace by renaming the druid-tree to a versioned directory' },
            { 'name' => 'end-accession', 'label' => 'Start text extraction workflows as needed' }
          ]
        }
      end
      let(:body) { template.to_json }

      it 'returns templates' do
        expect(client.template(workflow_name)).to eq(template)
      end
    end

    context 'when API request fails' do
      let(:status) { [500] }
      let(:body) { '{"errors":["error message here"]}' }

      it 'raises an error' do
        expect { client.template(workflow_name) }.to raise_error(Dor::Services::Client::UnexpectedResponse)
      end
    end
  end
end
