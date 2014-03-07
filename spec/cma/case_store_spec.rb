require 'spec_helper'
require 'cma/oft/mergers/case'
require 'cma/case_store'
require 'fileutils'

module CMA
  describe CaseStore do
    describe '.save' do
      let(:expected_filename) { 'spec/fixtures/store/mergers/1-2-3-Name.json' }
      let(:_case) do
        OFT::Mergers::Case.new.tap do |c|
          c.title = 'test'
          c.sector = 'test'
          c.original_url = 'http://oft.gov.uk/1/2/3/Name'
        end
      end

      before do
        FileUtils.rmtree 'spec/fixtures/store'
        CaseStore.instance.save(_case)
      end

      it 'saves the case' do
        expect(File).to exist(expected_filename)
      end

      describe 'loading the case' do
        subject { CaseStore.instance.load(expected_filename) }

        it                 { should be_an(OFT::Mergers::Case) }
        its(:title)        { should eql('test') }
        its(:sector)       { should eql('test') }
        its(:original_url) { should eql('http://oft.gov.uk/1/2/3/Name') }
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
