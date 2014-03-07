require 'spec_helper'
require 'cma/oft/mergers/case'

module CMA
  module OFT
    describe Mergers::Case do
      let(:doc)    { Nokogiri::HTML(File.read('spec/fixtures/oft/mergers.html')) }
      let(:row)    { doc.at_xpath('//table/tr[1]') }

      shared_examples 'it has all the row properties of Alliance Medical' do
        it                 { should be_a(Mergers::Case) }
        its(:title)        { should eql('Alliance Medical / IBA Molecular') }
        its(:case_type)    { should eql('mergers') }
        its(:sector)       { should eql('Healthcare') }
        its(:original_url) { should eql('http://oft.gov.uk/OFTwork/mergers/Mergers_Cases/2013/Alliance') }
        its(:base_name)    { should eql('OFTwork-mergers-Mergers_Cases-2013-Alliance')}
        its(:filename)     { should eql('mergers/OFTwork-mergers-Mergers_Cases-2013-Alliance.json')}
        its(:assets)       { should be_empty }
      end

      describe '.from_case_list_row' do
        context 'when row is nil' do
          it 'raises an ArgumentError' do
            expect { Mergers::Case.from_case_list_row(nil) }.to \
              raise_error(ArgumentError, /must be a Nokogiri::XML::Node/)
          end
        end

        context 'the happy path' do
          subject      { Mergers::Case.from_case_list_row(row) }

          it_should_behave_like 'it has all the row properties of Alliance Medical'
        end
      end

      describe 'serializing to the document store' do
        let(:mergers_case)  { Mergers::Case.from_case_list_row(row) }
        let(:expected_path) { 'spec/fixtures/store/mergers/OFTwork-mergers-Mergers_Cases-2013-Alliance.json' }

        before do
          mergers_case.save!
        end

        it 'saves to the default output path' do
          expect(File).to exist(expected_path)
        end

        describe 'loading it back' do
          subject { Mergers::Case.load(expected_path) }

          it_should_behave_like 'it has all the row properties of Alliance Medical'
        end
      end
    end
  end
end
