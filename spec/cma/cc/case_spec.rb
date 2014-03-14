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

        describe 'Lafarge breaking case' do
          let(:doc)    { Nokogiri::HTML(File.read('spec/fixtures/cc/lafarge.html')) }
          before { _case.add_case_detail(doc) }

          its(:date_of_referral)   { should eql(Date.new(2011, 9, 2)) }
          its(:statutory_deadline) { should eql(Date.new(2012, 5, 1)) }
        end

        describe 'Provisional final report breaking cases - stepping around Kramdown errors' do
          context 'bad style in aggregates final report' do
            # NoMethodError from Kramdown conversion - was due to
            # @style attribute in Kramdown table parsing. Fix by removing style attrs
            let(:doc)    { Nokogiri::HTML(File.read('spec/fixtures/cc/aggregates-provisional-final-report.html')) }
            before { _case.add_markdown_detail(doc, :provisional_final_report) }

            its(:provisional_final_report)   { should_not be_blank }
          end

          context 'bad table alignment in provisional-findings-report' do
            # NoMethodError from Kramdown conversion - was due to
            # bug in Kramdown thead parsing. Fix by removing thead els (not totally necessary)
            let(:doc)    { Nokogiri::HTML(File.read('spec/fixtures/cc/statutory-audit-provisional-findings-report.html')) }
            before { _case.add_markdown_detail(doc, :provisional_findings_report) }

            its(:provisional_findings_report)   { should_not be_blank }
          end
        end

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

        describe 'deciding what attr to use to save a subpage via .attr_for_url' do
          example 'second level subpage' do
            OurWork::Case.attr_for_url(
              'http://cc.org/our-work/directory-of-all-inquiries/anglo-american-lafarge/news-releases-and-announcements'
            ).should eql(:news_releases_and_announcements)
          end
          example 'third level subpage' do
            OurWork::Case.attr_for_url(
              'http://cc.org/our-work/directory-of-all-inquiries/anglo-american-lafarge/evidence/cc-commissioned-research-and-surveys'
            ).should eql([:evidence, 'cc-commissioned-research-and-surveys'])
          end
        end
      end
    end
  end
end
