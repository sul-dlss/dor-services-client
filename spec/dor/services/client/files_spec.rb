# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Files do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:pid) { 'druid:ck546xs5106' }

  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: pid) }

  describe '#list' do
    subject { client.list }
    context 'when the response is 200' do
      let(:body) do
        <<~JSON
          {"items":[{"id":"olemiss1.jp2","name":"olemiss1.jp2","selfLink":"https://dor-services-stage.stanford.edu/v1/objects/druid:ck546xs5106/contents/olemiss1.jp2"},
          {"id":"olemiss1.jpeg","name":"olemiss1.jpeg","selfLink":"https://dor-services-stage.stanford.edu/v1/objects/druid:ck546xs5106/contents/olemiss1.jpeg"},
          {"id":"olemiss1v.jp2","name":"olemiss1v.jp2","selfLink":"https://dor-services-stage.stanford.edu/v1/objects/druid:ck546xs5106/contents/olemiss1v.jp2"},
          {"id":"olemiss1v.jpeg","name":"olemiss1v.jpeg","selfLink":"https://dor-services-stage.stanford.edu/v1/objects/druid:ck546xs5106/contents/olemiss1v.jpeg"}]}
        JSON
      end

      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:ck546xs5106/contents')
          .to_return(status: 200, body: body)
      end

      it { is_expected.to eq ['olemiss1.jp2', 'olemiss1.jpeg', 'olemiss1v.jp2', 'olemiss1v.jpeg'] }
    end

    context 'when the response is 404' do
      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:ck546xs5106/contents')
          .to_return(status: 404, body: '')
      end

      it { is_expected.to eq [] }
    end
  end

  describe '#retrieve' do
    subject { client.retrieve(filename: 'olemiss1v.jp2') }
    context 'when the response is 200' do
      let(:body) do
        <<~BODY
          This is all the stuff in the file
        BODY
      end

      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:ck546xs5106/contents/olemiss1v.jp2')
          .to_return(status: 200, body: body)
      end

      it { is_expected.to eq "This is all the stuff in the file\n" }
    end

    context 'when the response is 404' do
      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:ck546xs5106/contents/olemiss1v.jp2')
          .to_return(status: 404, body: '')
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#preserved_content' do
    subject { client.preserved_content(filename: 'olemiss1v.jp2', version: 1) }
    before do
      stub_request(:get, 'https://dor-services.example.com/v1/sdr/objects/druid:ck546xs5106/content/olemiss1v.jp2?version=1')
        .to_return(status: status, body: body)
    end

    context 'when the response is 200' do
      let(:body) do
        <<~BODY
          This is all the stuff in the file
        BODY
      end

      let(:status) { 200 }

      it { is_expected.to eq "This is all the stuff in the file\n" }
    end

    context 'when the response is 404' do
      let(:status) { 404 }
      let(:body) { '' }

      it { is_expected.to be_nil }
    end
  end
end
