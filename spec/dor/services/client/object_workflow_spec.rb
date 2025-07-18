# frozen_string_literal: true

RSpec.describe Dor::Services::Client::ObjectWorkflow do
  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: druid, workflow_name: 'accessionWF') }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123', enable_get_retries: false)
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:druid) { 'druid:mw971zk1113' }
  let(:xml) do
    <<~XML
      <workflow repository="dor" objectId="druid:mw971zk1113" id="accessionWF">
        <process laneId="default" lifecycle="submitted" elapsed="0.0" attempts="1" datetime="2013-02-18T15:08:10-0800" status="completed" name="start-accession"/>
      </workflow>
    XML
  end

  describe '#find' do
    subject(:workflow) { client.find }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:mw971zk1113/workflows/accessionWF')
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) { xml }

      it 'returns the workflow' do
        expect(workflow).to be_a(Dor::Services::Response::Workflow)
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }
      let(:body) { '' }

      it 'raises a NotFoundResponse exception' do
        expect { workflow }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end
  end

  describe '#create' do
    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:mw971zk1113/workflows/accessionWF?lane-id=default&version=1')
        .to_return(status: status)
    end

    let(:status) { 201 }

    context 'when API request succeeds' do
      it 'does not raise' do
        expect { client.create(version: 1) }.not_to raise_error
      end
    end

    context 'when parameters are provided' do
      let(:context) { { foo: 'bar' } }

      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:mw971zk1113/workflows/accessionWF?lane-id=low&version=1')
          .with(
            headers: { 'Content-Type' => 'application/json' },
            body: { context: context }
          )
          .to_return(status: 201)
      end

      it 'does not raise' do
        expect { client.create(version: 1, context: context, lane_id: 'low') }.not_to raise_error
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }

      it 'raises a NotFoundResponse exception' do
        expect { client.create(version: 1) }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end
  end

  describe '#skip_all' do
    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:mw971zk1113/workflows/accessionWF/skip_all?note=I%20changed%20my%20mind')
        .to_return(status: status)
    end

    let(:status) { 204 }

    context 'when API request succeeds' do
      it 'does not raise' do
        expect { client.skip_all(note: 'I changed my mind') }.not_to raise_error
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }

      it 'raises a NotFoundResponse exception' do
        expect { client.skip_all(note: 'I changed my mind') }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end
  end

  describe '#process' do
    let(:process) { instance_double(Dor::Services::Client::Process) }

    before do
      allow(Dor::Services::Client::Process).to receive(:new).and_return(process)
    end

    it 'returns a Process' do
      expect(client.process('shelve')).to eq(process)

      expect(Dor::Services::Client::Process).to have_received(:new).with(
        connection: connection,
        version: 'v1',
        object_identifier: druid,
        workflow_name: 'accessionWF',
        process: 'shelve',
        object_workflow_client: client
      )
    end
  end
end
