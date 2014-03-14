require 'spec_helper'
require 'cma/cc/our_work/case'
require 'cma/asset'
require 'cma/case_store'

module CMA
  module CC
    describe OurWork::Case do
      let(:doc)    { Nokogiri::HTML(File.read('spec/fixtures/cc/aggregates.html')) }

      describe '.add_case_detail' do
        subject(:_case) do
          OurWork::Case.new.tap do |c|
            c.title         = 'original'
            c.original_url  = 'http://www.competition-commission.org.uk/our-work/url'
          end
        end

        before { _case.add_case_detail(doc) }
        after  { CaseStore.instance.clean! }

        its(:title)              { should eql('Aggregates, cement and ready-mix concrete market investigation') }
        its(:date_of_referral)   { should eql(Date.new(2012, 1, 18)) }
        its(:statutory_deadline) { should eql(Date.new(2014, 1, 17)) }

        describe 'core documents markup' do
          subject { _case.core_documents }

          it 'has the header' do
            subject.should include('# Aggregates, cement and ready-mix concrete market investigation')
          end
          it 'has no ruler' do
            should_not include('* * *')
          end
          it 'has list items that are links' do
            subject.should include '* [Terms of reference (PDF, 13'
            subject.should include '(/assets/competitioncommission/docs/2012/aggregates-cement-and-ready-mix-concrete/agg_terms_of_reference.pdf)'
          end

          it_behaves_like 'it has no markup or fluff'
        end
      end
    end
  end
end