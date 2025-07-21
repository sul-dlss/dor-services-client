# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Process do
  subject(:client) do
    described_class.new(connection: connection, version: 'v1', object_identifier: druid,
                        workflow_name: 'accessionWF', process: process, object_workflow_client: object_workflow_client)
  end

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123', enable_get_retries: false)
    stub_request(:put, 'https://dor-services.example.com/v1/objects/druid:mw971zk1113/workflows/accessionWF/processes/shelve')
      .with(
        headers: { 'Content-Type' => 'application/json' },
        body: body
      )
      .to_return(status: status)
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:status) { 204 }
  let(:druid) { 'druid:mw971zk1113' }
  let(:object_workflow_client) { instance_double(Dor::Services::Client::ObjectWorkflow) }
  let(:process) { 'shelve' }

  let(:body) do
    {
      status: 'completed',
      elapsed: 0
    }
  end

  describe '#update' do
    context 'when API request succeeds' do
      it 'does not raise' do
        expect { client.update(status: 'completed') }.not_to raise_error
      end
    end

    context 'when API request succeeds with additional parameters' do
      let(:body) do
        {
          status: 'completed',
          elapsed: 5.5,
          lifecycle: 'publish',
          note: 'All good'
        }
      end

      it 'does not raise' do
        expect { client.update(status: 'completed', elapsed: 5.5, lifecycle: 'publish', note: 'All good') }.not_to raise_error
      end
    end

    context 'when API request returns 409' do
      let(:status) { [409, 'conflict'] }

      let(:body) do
        {
          status: 'completed',
          elapsed: 0,
          current_status: 'started'
        }
      end

      it 'raises a ConflictResponse exception' do
        expect { client.update(status: 'completed', current_status: 'started') }.to raise_error(Dor::Services::Client::ConflictResponse)
      end
    end
  end

  describe '#update_error' do
    let(:body) do
      {
        status: 'error',
        error_msg: 'Ooops',
        error_text: 'the backtrace'
      }
    end

    it 'does not raise' do
      expect { client.update_error(error_msg: 'Ooops', error_text: 'the backtrace') }.not_to raise_error
    end
  end

  describe '#status' do
    subject(:workflow_status) { client.status }

    let(:workflow) { instance_double(Dor::Services::Response::Workflow, ng_xml: Nokogiri::XML(xml)) }
    let(:process) { 'registrar-approval' }

    before do
      allow(object_workflow_client).to receive(:find).and_return(workflow)
    end

    context 'when a single result is returned' do
      let(:xml) do
        '<workflow><process name="registrar-approval" status="completed" /></workflow>'
      end

      it 'returns status as a string' do
        expect(workflow_status).to eq('completed')
      end
    end

    context 'when a multiple versions are returned' do
      let(:xml) do
        '<workflow><process name="registrar-approval" version="1" status="completed" />
          <process name="registrar-approval" version="2" status="waiting" /></workflow>'
      end

      it 'returns the status for the highest version' do
        expect(workflow_status).to eq('waiting')
      end
    end

    context 'when the workflow/process combination does not exist' do
      let(:xml) do
        '<workflow><process name="registrar-approval" status="completed" /></workflow>'
      end
      let(:process) { 'publish' }

      it 'returns nil' do
        expect(workflow_status).to be_nil
      end
    end
  end
end
