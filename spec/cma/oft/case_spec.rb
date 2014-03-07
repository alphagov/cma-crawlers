require 'cma/oft/mergers/case'

module CMA
  module OFT
    describe Mergers::Case do
      describe '.from_case_list_row' do
        context 'when row is nil' do
          it 'raises an ArgumentError' do
            expect { Mergers::Case.from_case_list_row(nil) }.to \
              raise_error(ArgumentError, /must be a Nokogiri::XML::Node/)
          end
        end

        context 'the happy path' do
          let(:doc)    { Nokogiri::HTML(File.read('spec/fixtures/oft/mergers.html')) }
          let(:row)    { doc.at_xpath('//table/tr[1]') }

          subject      { Mergers::Case.from_case_list_row(row) }

          it                 { should be_a(Mergers::Case) }
          its(:title)        { should eql('Alliance Medical / IBA Molecular') }
          its(:sector)       { should eql('Healthcare') }
          its(:original_url) { should eql('http://oft.gov.uk/OFTwork/mergers/Mergers_Cases/2013/Alliance') }
          its(:assets)       { should be_empty }
        end
      end
    end
  end
end
