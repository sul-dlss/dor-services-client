# frozen_string_literal: true

RSpec.describe Dor::Services::Client::ObjectWorkflow do
  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: druid, workflow_name: 'accessionWF') }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123', enable_get_retries: false)
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:druid) { 'druid:mw971zk1113' }

  let(:ng_xml) { Nokogiri::XML(xml) }
  let(:xml) do
    <<~XML
      <workflow repository="dor" objectId="druid:mw971zk1113" id="accessionWF">
        <process laneId="default" lifecycle="submitted" elapsed="0.0" attempts="1" datetime="2013-02-18T15:08:10-0800" status="completed" name="start-accession"/>
      </workflow>
    XML
  end

  describe '#find' do
    subject(:workflows) { client.find }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:mw971zk1113/workflows/accessionWF')
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) { xml }

      it 'returns the workflows' do
        expect(workflows).to be_a(Dor::Services::Response::Workflow)
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }
      let(:body) { '' }

      it 'raises a NotFoundResponse exception' do
        expect { workflows }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end
  end
end
