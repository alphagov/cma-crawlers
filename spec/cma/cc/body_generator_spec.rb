require 'spec_helper'
require 'cma/cc/body_generator'
require 'cma/case_store'

describe CMA::CC::BodyGenerator do

  describe 'creating a new one' do
    let(:location)          { 'spec/fixtures/store' }
    let(:aggregates_name)   { 'our-work-directory-of-all-inquiries-aggregates-cement-ready-mix-concrete.json' }
    let(:aggregates_path)   { File.join('spec/fixtures/cc', aggregates_name) }

    before do
      FileUtils.mkdir_p(location)
      FileUtils.cp(aggregates_path, location)
    end

    after do
      FileUtils.rmtree(location)
    end

    subject(:body_generator) { CMA::CC::BodyGenerator.new }

    describe '#generate!' do
      before do
        body_generator.generate!
      end

      subject(:case_body) do
        CMA::CaseStore.instance.load(File.join(location, aggregates_name)).body
      end

      it 'begins with an h2 Phase 2 header' do
        case_body.should match /^## Phase 2/
      end

      it 'uses the date of referral' do
        case_body.should have_content('Date of referral:  18/01/2012').under('## Phase 2')
      end
      it 'uses the statutory deadline' do
        case_body.should have_content('Statutory deadline:  17/01/2014').under('## Phase 2')
      end

      it 'puts the CC headers at h3' do
        case_body.should include('### Core documents')
      end
      it 'puts the OFT headers at h3' do
        case_body.should include('### Aggregates')
      end
      it 'excludes the useless analysis page' do
        case_body.should_not include("Analysis\n\n* [Working\n  papers]")
      end

      describe 'included useful analysis content' do
        it 'has content under an h3' do
          should have_content('Working Papers are published').under('### Working papers')
        end
        it { should include('[Notification of the CC’s intention to carry out case studies') }
        it { should include('[Commentary on the Cement Profitability Analysis') }
      end

      describe 'included useful evidence content' do
        it { should include '### Summaries of hearings held with parties' }
        it { should include '### Responses to updated issues statement' }
        it { should include '### Responses to issues' }
      end

      describe 'the news section' do
        it { should include '### News releases' }
        it { should include '[Issues statement news' }
      end

      describe 'the OFT sections' do
        it { should include '## Phase 1'}
        it 'has the reference' do
          should include '**Date of reference:** 18 January 2012'
        end
        it 'has the work summary' do
          '### Summary of work'
        end
      end

      describe 'the absence of tables' do
        it { should_not include('<table') }
        it { should_not include('<html') }
        it { should_not include('<body') }

CEMENT_CUSTOMER_SWITCHING = %Q{
* [Cement customer switching (PDF, 613
  Kb)](http://www.competition-commission.org.uk/assets/competitioncommission/docs/2012/aggregates-cement-and-ready-mix-concrete/cement_switching_slides_for_publication_non_con.pdf)
  08.02.13
}

        it { should include(CEMENT_CUSTOMER_SWITCHING)}

ANALYSIS_OF_COST_STRUCTURES = %q{Analysis of cost structures and profit margins
  * [Part I: Purpose, approach and methodology (PDF, 170
    Kb)](http://www.competition-commission.org.uk/assets/competitioncommission/docs/2012/aggregates-cement-and-ready-mix-concrete/analysis_of_cost_structures_and_profit_margins_part_1_excised.pdf)
  * [Part II: Assessment covering the Majors’ relevant GB operations
    (PDF, 501
    Kb)](http://www.competition-commission.org.uk/assets/competitioncommission/docs/2012/aggregates-cement-and-ready-mix-concrete/analysis_of_cost_structures_and_profit_margins_part_2_excised.pdf)
  * [Part III: Assessment covering the medium-tier independents’
    relevant GB operations (PDF, 251
    Kb)](http://www.competition-commission.org.uk/assets/competitioncommission/docs/2012/aggregates-cement-and-ready-mix-concrete/analysis_of_cost_structures_and_profit_margins_part_3_excised.pdf)
  * [Glossary (PDF, 44
    Kb)](http://www.competition-commission.org.uk/assets/competitioncommission/docs/2012/aggregates-cement-and-ready-mix-concrete/analysis_of_cost_structures_and_profit_margins_glossary.pdf)
} + "  " + %q{
  27\.03.13
}
        it "should convert nested lists" do
          converted_nested_list = subject.split(/^\* /).find {|p| p.include?("Analysis of cost structures and profit margins")}
          expect(converted_nested_list).to_not be_nil
          expect(converted_nested_list).to eq(ANALYSIS_OF_COST_STRUCTURES)
        end
      end
    end
  end

end
