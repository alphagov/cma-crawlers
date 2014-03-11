require 'spec_helper'
require 'cma/oft/mergers/case'
require 'cma/asset'

module CMA
  module OFT
    describe Mergers::Case do
      let(:doc)    { Nokogiri::HTML(File.read('spec/fixtures/oft/mergers.html')) }
      let(:row)    { doc.at_xpath('//table/tr[1]') }

      shared_examples 'it has all the row properties of Alliance Medical' do
        it                 { should be_a(Mergers::Case) }
        its(:title)        { should eql('Alliance Medical / IBA Molecular') }
        its(:case_state)   { should eql('open') }
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
        subject(:mergers_case) { Mergers::Case.from_case_list_row(row) }
        let(:expected_path)    { 'spec/fixtures/store/OFTwork-mergers-Mergers_Cases-2013-Alliance.json' }

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

        its(:serializable_hash) do
          should eql({
                       'title' => 'Alliance Medical / IBA Molecular',
                       'original_url' => 'http://oft.gov.uk/OFTwork/mergers/Mergers_Cases/2013/Alliance',
                       'sector' => 'Healthcare',
                       'case_type' => 'mergers',
                       'case_state' => 'open'
                     })
        end


        describe 'loading it back' do
          subject(:_case) { Mergers::Case.load(expected_path) }

          it_should_behave_like 'it has all the row properties of Alliance Medical'

          shared_examples 'it has no markup or fluff' do
            it { should_not include '<p>'}
            it { should_not include '&nbsp;'}
            it { should_not include '<script'}
            it { should_not include '<span>'}
            it { should_not include '<div'}
            it { should_not include '[Initial'}
            it { should_not include 'backtotop'}
          end

          describe 'augmenting the case with the top-level case page' do
            before do
              _case.add_details_from_case(
                Nokogiri::HTML(File.read('spec/fixtures/oft/Arriva.html')),
                :invitation_to_comment
              )
            end

            describe 'the markdown for the invitation to comment' do
              subject { _case.invitation_to_comment }

              it { should include 'Informal Submission' }
              it { should include 'to arrive by' }

              it_behaves_like 'it has no markup or fluff'
            end
          end

          describe 'augmenting the case with the initial undertakings' do
            before do
              _case.add_details_from_case(
                Nokogiri::HTML(File.read('spec/fixtures/oft/Arriva-Initial-Undertakings.html')),
                :initial_undertakings
              )
            end

            describe 'the markdown for the initial undertakings' do
              subject { _case.initial_undertakings }

              it { should include '**Name of acquirer:' }

              it_behaves_like 'it has no markup or fluff'
            end
          end

          describe 'adding an asset' do
            let(:asset) do
              CMA::Asset.new(
                'http://some.asset/name.pdf',
                _case,
                'PDF 1.6/Content',
                'application/pdf'
              )
            end
            let(:assets) { [asset, asset.dup] }

            before { _case.assets = assets }

            it 'serializes the asset to JSON' do
              JSON.load(_case.to_json)['assets'].should eql(
                [{
                   'original_url' => 'http://some.asset/name.pdf',
                   'content_type' => 'application/pdf',
                   'filename'     => 'OFTwork-mergers-Mergers_Cases-2013-Alliance/name.pdf'
                 },
                 {
                   'original_url' =>
                     'http://some.asset/name.pdf',
                   'content_type' => 'application/pdf',
                   'filename'     => 'OFTwork-mergers-Mergers_Cases-2013-Alliance/name.pdf' }
                ]
              )
            end
          end
        end
      end
    end
  end
end
