# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Embargo do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }

  subject(:client) do
    described_class.new(connection: connection,
                        object_identifier: 'druid:1234',
                        version: 'v1')
  end

  describe '#update' do
    let(:params) { { embargo_date: '2099-12-13', requesting_user: 'mjg' } }

    before do
      stub_request(:patch, 'https://dor-services.example.com/v1/objects/druid:1234/embargo')
        .with(
          body: '{"embargo_date":"2099-12-13","requesting_user":"mjg"}',
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(status: status)
    end

    context 'when API request succeeds' do
      let(:status) { 204 }

      it 'posts params as json' do
        expect(client.update(params)).to be_nil
      end
    end

    context 'when API request fails' do
      let(:status) { [404, 'not found'] }

      it 'raises an error' do
        expect { client.update(params) }.to(
          raise_error(Dor::Services::Client::NotFoundResponse,
                      "not found: 404 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY}) for druid:1234")
        )
      end
    end
  end
end
