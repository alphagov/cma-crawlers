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
        its(:state)        { should eql('open') }
        its(:case_type)    { should eql('mergers') }
        its(:sector)       { should eql('Healthcare') }
        its(:original_url) { should eql('http://oft.gov.uk/OFTwork/mergers/Mergers_Cases/2013/Alliance') }
        its(:base_name)    { should eql('OFTwork-mergers-Mergers_Cases-2013-Alliance')}
        its(:filename)     { should eql('OFTwork-mergers-Mergers_Cases-2013-Alliance.json')}
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
        let(:expected_path) { 'spec/fixtures/store/OFTwork-mergers-Mergers_Cases-2013-Alliance.json' }

        before do
          CaseStore.instance.clean!
          mergers_case.save!
        end

        after do
          CaseStore.instance.clean!
        end

        it 'saves to the default output path' do
          expect(File).to exist(expected_path)
        end

        describe 'loading it back' do
          subject(:_case) { Mergers::Case.load(expected_path) }

          it_should_behave_like 'it has all the row properties of Alliance Medical'

          describe 'augmenting the case with the top-level case page' do
            before do
              _case.add_details_from_case(
                Nokogiri::HTML(File.read('spec/fixtures/oft/Arriva.html')))
            end

            describe 'the markdown for the invitation to comment' do
              subject { _case.invitation_to_comment }

              before { puts _case.invitation_to_comment }

              it { should include 'Informal Submission' }
              it { should include 'to arrive by' }
              it { should_not include '<p>'}
              it { should_not include '&nbsp;'}
              it { should_not include '<script'}
              it { should_not include '<span>'}
              it { should_not include '<div'}
              it { should_not include '[Initial'}
              it { should_not include 'backtotop'}
            end
          end

          describe 'adding an asset' do
            before { _case.assets << Asset.new(File.read('spec/fixtures/oft/APS-letter.pdf'))}
          end
        end
      end
    end
  end
end
