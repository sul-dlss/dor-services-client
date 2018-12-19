# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Workflow do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com')
  end
  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  subject(:client) { described_class.new(connection: connection) }

  describe '#create' do
    let(:pid) { 'druid:123' }
    subject(:request) { client.create(object: pid, wf_name: 'accessionWF') }
    context 'when API request succeeds' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:123/apo_workflows/accessionWF')
          .to_return(status: 200)
      end

      it 'posts params' do
        expect(request).to be nil
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:123/apo_workflows/accessionWF')
          .to_return(status: [500, 'something is amiss'])
      end

      it 'raises an error' do
        expect { request }.to raise_error('something is amiss: 500 ()')
      end
    end
  end
end