# frozen_string_literal: true

require 'active_support/core_ext/time'

RSpec.describe Dor::Services::Client::Metadata do
  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: pid) }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:pid) { 'druid:1234' }

  describe '#dublin_core' do
    subject(:response) { client.dublin_core }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/metadata/dublin_core')
        .to_return(status: status, body: body)
    end

    context 'when the object is found' do
      let(:status) { 200 }
      let(:body) { '<dc />' }

      it { is_expected.to eq '<dc />' }
    end

    context 'when the object is not found' do
      let(:status) { 404 }
      let(:body) { '' }

      it { is_expected.to be_nil }
    end

    context 'when there is a server error' do
      let(:status) { [500, 'internal server error'] }
      let(:body) { 'broken' }

      it 'raises an error' do
        expect { response }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                           'internal server error: 500 (broken) for druid:1234')
      end
    end
  end

  describe '#public_xml' do
    subject(:response) { client.public_xml }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/metadata/public_xml')
        .to_return(status: status, body: body)
    end

    context 'when the object is found' do
      let(:status) { 200 }
      let(:body) do
        <<~XML
          <publicObject id="druid:1234" published="2021-04-23T19:43:06Z" publishVersion="dor-services/9.6.2">
            <identityMetadata/>
            <rightsMetadata>
              <access type="discover">
                <machine>
                  <none/>
                </machine>
              </access>
              <access type="read">
                <machine>
                  <none/>
                </machine>
              </access>
              <use>
                <human type="useAndReproduction"/>
                <human type="creativeCommons"/>
                <machine type="creativeCommons" uri=""/>
                <human type="openDataCommons"/>
                <machine type="openDataCommons" uri=""/>
              </use>
              <copyright>
                <human/>
              </copyright>
            </rightsMetadata>
          </publicObject>
        XML
      end

      it { is_expected.to eq body }
    end

    context 'when the object is not found' do
      let(:status) { 404 }
      let(:body) { '' }

      it { is_expected.to be_nil }
    end

    context 'when there is a server error' do
      let(:status) { [500, 'internal server error'] }
      let(:body) { 'broken' }

      it 'raises an error' do
        expect { response }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                           'internal server error: 500 (broken) for druid:1234')
      end
    end
  end

  describe '#descriptive' do
    subject(:response) { client.descriptive }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/metadata/descriptive')
        .to_return(status: status, body: body)
    end

    context 'when the object is found' do
      let(:status) { 200 }
      let(:body) { '<publicObject />' }

      it { is_expected.to eq '<publicObject />' }
    end

    context 'when the object is not found' do
      let(:status) { 404 }
      let(:body) { '' }

      it { is_expected.to be_nil }
    end

    context 'when there is a server error' do
      let(:status) { [500, 'internal server error'] }
      let(:body) { 'broken' }

      it 'raises an error' do
        expect { response }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                           'internal server error: 500 (broken) for druid:1234')
      end
    end
  end

  describe '#mods' do
    subject(:response) { client.mods }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:1234/metadata/mods')
        .to_return(status: status, body: body)
    end

    context 'when the object is found' do
      let(:status) { 200 }
      let(:body) { '<mods />' }

      it { is_expected.to eq '<mods />' }
    end

    context 'when the object is not found' do
      let(:status) { 404 }
      let(:body) { '' }

      it { is_expected.to be_nil }
    end

    context 'when there is a server error' do
      let(:status) { [500, 'internal server error'] }
      let(:body) { 'broken' }

      it 'raises an error' do
        expect { response }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                           'internal server error: 500 (broken) for druid:1234')
      end
    end
  end
end
