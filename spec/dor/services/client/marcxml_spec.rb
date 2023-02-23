# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Marcxml do
  subject(:client) { described_class.new(connection: connection, version: 'v1') }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:barcode) { 'abc123' }
  let(:connection) { Dor::Services::Client.instance.send(:connection) }

  describe '#marcxml' do
    let(:catkey) { '12345678' }

    let(:status) { 200 }

    let(:body) do
      <<-EOXML
      <?xml version="1.0"?>
        <record xmlns="http://www.loc.gov/MARC21/slim">
        <leader>     cam a22     Ia 4500</leader>
        <controlfield tag="005">20130318221743.0</controlfield>
        <controlfield tag="008">921116s1992    moua     b    000 0 eng d</controlfield>
        <datafield ind1=" " ind2=" " tag="035">
          <subfield code="a">180345</subfield>
            </datafield>
        <datafield ind1=" " ind2=" " tag="040">
          <subfield code="a">DBI</subfield>
            <subfield code="c">DBI</subfield>
          <subfield code="d">OCL</subfield>
            <subfield code="d">OCLCQ</subfield>
        </datafield>
      </record>
      EOXML
    end

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/catalog/marcxml')
        .with(
          query: { 'barcode' => barcode }
        )
        .to_return(status: status, body: body)
      stub_request(:get, 'https://dor-services.example.com/v1/catalog/marcxml')
        .with(
          query: { 'catkey' => catkey }
        )
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds with barcode and there is a body' do
      it 'returns the MARCXML' do
        expect(client.marcxml(barcode: barcode)).to eq(body)
      end
    end

    context 'when API request succeeds with catkey and there is a body' do
      it 'returns the MARCXML' do
        expect(client.marcxml(catkey: catkey)).to eq(body)
      end
    end

    context 'when API request fails with 500 (Record not found in Symphony)' do
      let(:status) { 500 }
      let(:body) { 'Record not found in Symphony: ' }

      it 'raises a NotFoundResponse error' do
        expect { client.marcxml(barcode: barcode) }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end

    context 'when API request fails with other 500' do
      let(:status) { [500, 'internal server error'] }
      let(:body) { '' }

      it 'raises an error' do
        expect { client.marcxml(barcode: barcode) }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                                                   /internal server error: 500 /)
      end
    end

    context 'when barcode or catkey not provided' do
      it 'raises ArgumentError' do
        expect { client.marcxml }.to raise_error(ArgumentError)
      end
    end

    context 'when both barcode and catkey provided' do
      it 'raises ArgumentError' do
        expect { client.marcxml(barcode: barcode, catkey: catkey) }.to raise_error(ArgumentError)
      end
    end
  end
end
