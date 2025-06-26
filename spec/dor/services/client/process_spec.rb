# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Process do
  subject(:client) do
    described_class.new(connection: connection, version: 'v1', object_identifier: druid,
                        workflow_name: 'accessionWF', process: 'shelve')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:druid) { 'druid:mw971zk1113' }

  describe '#status' do
    let(:status) { 200 }
    let(:workflow_status) { 'completed' }

    before do
      Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123', enable_get_retries: false)
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:mw971zk1113/workflows/accessionWF/processes/shelve')
        .with(
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(status: status, body: { status: workflow_status }.to_json)
    end

    context 'when API request succeeds' do
      it 'returns the status' do
        expect(client.status).to eq workflow_status
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }

      it 'raises a NotFoundResponse exception' do
        expect { client.status }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end
  end

  describe '#update' do
    let(:status) { 204 }

    before do
      Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123', enable_get_retries: false)
      stub_request(:put, 'https://dor-services.example.com/v1/objects/druid:mw971zk1113/workflows/accessionWF/processes/shelve')
        .with(
          headers: { 'Content-Type' => 'application/json' },
          body: body
        )
        .to_return(status: status)
    end

    context 'when API request succeeds' do
      let(:body) do
        {
          status: 'completed',
          elapsed: 0
        }
      end

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
    let(:status) { 204 }
    let(:body) do
      {
        status: 'error',
        error_msg: 'Ooops',
        error_text: 'the backtrace'
      }
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

    it 'does not raise' do
      expect { client.update_error(error_msg: 'Ooops', error_text: 'the backtrace') }.not_to raise_error
    end
  end
end
