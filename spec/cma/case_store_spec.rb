require 'spec_helper'
require 'cma/oft/mergers/case'
require 'cma/oft/competition/case'
require 'cma/oft/consumer/case'
require 'cma/cc/our_work/case'
require 'cma/case_store'
require 'cma/asset'
require 'fileutils'

module CMA
  describe CaseStore do
    describe '.save' do
      let(:expected_filename) { 'spec/fixtures/store/OFTwork-mergers-Mergers_Cases-2013-DiageoUnitedSpirits.json' }
      let(:_case) do
        OFT::Mergers::Case.new.tap do |c|
          c.title = 'test_title'
          c.sector = 'test_sector'
          c.original_url = 'http://oft.gov.uk/OFTwork/mergers/Mergers_Cases/2013/DiageoUnitedSpirits'
          c.original_urls << 'http://oft.gov.uk/somewhere/special'

          c.assets << CMA::Asset.new('http://1', c, '1234', 'text/plain')
        end
      end

      before do
        FileUtils.rmtree 'spec/fixtures/store'
        CaseStore.instance.save(_case)
      end

      it 'saves the case' do
        expect(File).to exist(expected_filename)
      end

      describe 'what to load via .load_class' do
        it 'loads a Mergers case for a merger URL' do
          CaseStore.instance.load_class('Somestore/OFTwork-mergers-Mergers_Cases-2013-Alliance.json').
            should == CMA::OFT::Mergers::Case
        end
        it 'loads a Competition case for a competition URL' do
          CaseStore.instance.load_class('somestore/OFTwork-oft-current-cases-competition-case-list-2005-interchage-fees-mastercard.json').
            should == CMA::OFT::Competition::Case
        end
        it 'loads a Consumer case for a consumer URL' do
          CaseStore.instance.load_class('somestore/OFTwork-oft-current-cases-consumer-case-list-2012-furniture-carpets.json').
            should == CMA::OFT::Consumer::Case
        end
        it 'loads a Markets case for a markets URL' do
          CaseStore.instance.load_class('somestore/OFTwork-oft-current-cases-markets-work2013/higher-education-cfi.json').
            should == CMA::OFT::Markets::Case
        end
        it 'loads a Markets case for a markets URL' do
          CaseStore.instance.load_class('_output/OFTwork-oft-current-cases-market-studies-2012-personal-current-accounts.json').
            should == CMA::OFT::Markets::Case
        end
        it 'loads a CC case for a CC URL' do
          CaseStore.instance.load_class('_output/our-work-directory-of-all-inquiries-aggregates-cement-ready-mix-concrete.json').
            should == CMA::CC::OurWork::Case
        end
      end

      describe 'loading the case' do
        subject { CaseStore.instance.load(expected_filename) }

        it                  { should be_an(OFT::Mergers::Case) }
        its(:title)         { should eql('test_title') }
        its(:sector)        { should eql('test_sector') }
        its(:original_url)  { should eql('http://oft.gov.uk/OFTwork/mergers/Mergers_Cases/2013/DiageoUnitedSpirits') }
        its(:original_urls) {
          should eql Set.new(%w(
            http://oft.gov.uk/OFTwork/mergers/Mergers_Cases/2013/DiageoUnitedSpirits
            http://oft.gov.uk/somewhere/special
          ))
        }
      end

      describe 'hanging onto markup sections' do
        let(:_case) do
          CC::OurWork::Case.new.tap do |c|
            c.original_url = 'http://cc.org/our-work/directory-of-all-inquiries/aggregates'
            c.markup_sections['core_documents'] = '# Hi'
            c.markup_sections['evidence/stuff'] = '# Hi'
          end
        end

        before { _case.save! }

        subject do
          CaseStore.instance.load(File.join('spec/fixtures/store', _case.filename))
        end

        its(:markup_sections) {
          should eql({
            'core_documents' => '# Hi',
            'evidence/stuff' => '# Hi'
          })
        }
      end

      describe 'finding the case by URL' do
        subject { CaseStore.instance.find('http://oft.gov.uk/OFTwork/mergers/Mergers_Cases/2013/DiageoUnitedSpirits') }

        it { should be_an(OFT::Mergers::Case) }
      end

      describe 'cleaning the store' do
        before { CaseStore.instance.clean! }

        it 'has obliterated everything' do
          Dir["#{CaseStore.instance.location}/*"].should have(0).entries
        end
      end
    end
  end
end
