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
            c.original_url  = 'http://www.competition-commission.org.uk/our-work/directory-of-all-inquiries/aggregates-cement-ready-mix-concrete'
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

        describe '#add_markdown_detail' do
          describe 'Provisional final report breaking cases - stepping around Kramdown errors' do
            context 'bad style in aggregates final report' do
              # NoMethodError from Kramdown conversion - was due to
              # @style attribute in Kramdown table parsing. Fix by removing style attrs
              let(:doc) { Nokogiri::HTML(File.read('spec/fixtures/cc/aggregates-provisional-final-report.html')) }
              before    { _case.add_markdown_detail(doc, 'provisional_final_report') }

              specify { _case.markup_sections['provisional_final_report'].should_not be_blank }
            end

            context 'bad table alignment in provisional-findings-report' do
              # NoMethodError from Kramdown conversion - was due to
              # bug in Kramdown thead parsing. Fix by removing thead els (not totally necessary)
              let(:doc) { Nokogiri::HTML(File.read('spec/fixtures/cc/statutory-audit-provisional-findings-report.html')) }
              before    { _case.add_markdown_detail(doc, 'provisional_findings_report') }

              specify { _case.markup_sections['provisional_findings_report'].should_not be_blank }
            end
          end

          context 'adding a part of a content bucket URL like .../evidence or .../analysis' do
            let(:doc) do
              html = <<HTML
              <div id="mainColumn">
                <h1>Working papers title</h1>
                <p>01.01.01</p><p></p><p>01.01.01</p>
              <div>
HTML
              Nokogiri::HTML.fragment(html)
            end
            before { _case.add_markdown_detail(doc, 'analysis/working-papers')}

            it 'puts markdown in the analysis/working-papers element of the markup_sections hash' do
              _case.markup_sections['analysis/working-papers'].should include('# Working papers title')
            end

            describe 'serializing this' do
              before  { _case.save! }
              subject { CaseStore.instance.load("spec/fixtures/store/#{_case.filename}") }

              its(:markup_sections) { should be_a(Hash) }
            end
          end
        end

        describe 'core documents markup' do
          subject { _case.markup_sections['core_documents'] }

          it 'has the header' do
            subject.should include('# Aggregates, cement and ready-mix concrete market investigation')
          end
          it 'has no ruler' do
            should_not include('* * *')
          end
          it 'has list items that are rewritten links' do
            subject.should include '* [Terms of reference (PDF, 13 Kb)][1]'
            subject.should include
              '[1]: http://www.competition-commission.org.uk'\
              '/assets/competitioncommission/docs/2012/aggregates-cement-and-ready-mix-concrete/agg_terms_of_reference.pdf'
          end

          it_behaves_like 'it has no markup or fluff'
        end
      end
    end
  end
end
