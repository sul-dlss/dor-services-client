# frozen_string_literal: true

RSpec.describe Dor::Services::Client::ReleaseTags do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com')
  end
  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  subject(:client) { described_class.new(connection: connection, version: 'v1') }

  describe '#create' do
    let(:pid) { 'druid:123' }
    subject(:request) { client.create(object: pid, release: true, to: 'searchworks', who: 'justin', what: 'foo') }
    context 'when API request succeeds' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:123/release_tags')
          .to_return(status: 201)
      end

      it 'posts tags' do
        expect(request).to be true
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:123/release_tags')
          .to_return(status: [500, 'something is amiss'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse, 'something is amiss: 500 ()')
      end
    end
  end
end
