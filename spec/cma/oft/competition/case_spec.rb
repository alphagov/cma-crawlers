require 'spec_helper'
require 'cma/oft/competition/case'
require 'cma/asset'

module CMA
  module OFT
    describe Competition::Case do
      let(:doc)    { Nokogiri::HTML(File.read('spec/fixtures/oft/oft-current.html')) }
      let(:row)    { doc.at_xpath('//table/tr[1]') }

      shared_examples 'it has all the row properties of Mastercard / VISA MIFs' do
        it                 { should be_a(Competition::Case) }
        its(:original_url) { should eql('http://oft.gov.uk/OFTwork/oft-current-cases/competition-case-list-2005/interchage-fees-mastercard') }
        its(:title)        { should eql('Mastercard / VISA MIFs') }
        its(:sector)       { should eql('financial-services') }
        its(:case_type)    { should eql('ca98-and-civil-cartels') }
      end

      describe '.from_case_list_row' do
        context 'when row is nil' do
          it 'raises an ArgumentError' do
            expect { Competition::Case.from_case_list_row(nil) }.to \
              raise_error(ArgumentError, /must be a Nokogiri::XML::Node/)
          end
        end

        context 'the happy path, first row' do
          subject      { Competition::Case.from_case_list_row(row) }

          it_should_behave_like 'it has all the row properties of Mastercard / VISA MIFs'
        end

        context 'second row, sector' do
          subject { Competition::Case.from_case_list_row(doc.at_xpath('//table/tr[2]'))}

          its(:sector) { should eql('motor-industry') }
        end

        context 'last row, criminal' do
          subject { Competition::Case.from_case_list_row(doc.at_xpath('//table/tr[last()]'))}

          its(:case_type) { should eql('criminal-cartels') }
        end
      end

      describe 'augmenting with' do
        subject(:_case) { Competition::Case.from_case_list_row(row) }

        describe 'summary from the CASE page' do
          before { _case.add_summary(Nokogiri::HTML(File.read('spec/fixtures/oft/mastercard-case.html'))) }

          its(:summary) { should start_with('The OFT is investigating') }
        end

        describe 'detail from the CASE_DETAIL page' do
          before { _case.add_detail(Nokogiri::HTML(File.read('spec/fixtures/oft/mastercard-case-detail.html'))) }

          subject(:body) { _case.body }

          it_behaves_like 'it has no markup or fluff'

          it { should include('The UK Government intervened') }
          it { should_not include('back to top') }
          it { should_not include('Content on this page') }
          it { should_not include('Back to:') }
        end
      end

      describe 'serializing to the document store' do
        subject(:competition_case) { Competition::Case.from_case_list_row(row) }
        let(:expected_path)    { 'spec/fixtures/store/OFTwork-oft-current-cases-competition-case-list-2005-interchage-fees-mastercard.json' }

        before do
          CaseStore.instance.clean!
          competition_case.save!
        end

        after do
          CaseStore.instance.clean!
        end

        it 'saves to the default output path' do
          expect(File).to exist(expected_path)
        end

        its(:serializable_hash) do
          should eql({
                       'title'        => 'Mastercard / VISA MIFs',
                       'original_url' => 'http://oft.gov.uk/OFTwork/oft-current-cases/competition-case-list-2005/interchage-fees-mastercard',
                       'sector'       => 'financial-services',
                       'case_type'    => 'ca98-and-civil-cartels',
                       'case_state'   => 'open'
                     })
        end


        describe 'loading it back' do
          subject(:_case) { Competition::Case.load(expected_path) }

          it_should_behave_like 'it has all the row properties of Mastercard / VISA MIFs'

          shared_examples 'it has no markup or fluff' do
            it { should_not include '<p>'}
            it { should_not include '&nbsp;'}
            it { should_not include '<script'}
            it { should_not include '<span>'}
            it { should_not include '<div'}
            it { should_not include '[Initial'}
            it { should_not include 'backtotop'}
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

            before { assets.each { |a| _case.assets << a } }

            it 'serializes the asset to JSON' do
              JSON.load(_case.to_json)['assets'].should eql(
                [{
                   'original_url' => 'http://some.asset/name.pdf',
                   'content_type' => 'application/pdf',
                   'filename'     => 'OFTwork-oft-current-cases-competition-case-list-2005-interchage-fees-mastercard/name.pdf'
                 },
                 {
                   'original_url' =>
                     'http://some.asset/name.pdf',
                   'content_type' => 'application/pdf',
                   'filename'     => 'OFTwork-oft-current-cases-competition-case-list-2005-interchage-fees-mastercard/name.pdf' }
                ]
              )
            end
          end
        end
      end
    end
  end
end
