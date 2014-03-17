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

      it 'uses the date of referral and statutory deadline' do
        pending
      end

      it 'puts the CC headers at h3' do
        case_body.should include('### Core documents')
      end
      it 'puts the OFT headers at h3' do
        pending 'not got that far yet'
        case_body.should include('###  Aggregates')
      end
      it 'excludes the useless analysis page' do
        case_body.should_not include("Analysis\n\n* [Working\n  papers]")
      end

      describe 'included useful analysis content' do
        it { should include('Working Papers are published') }
        it { should include('[Notification of the CC’s intention to carry out case studies') }
        it { should include('[Commentary on the Cement Profitability Analysis') }
        it 'has set their headers to h3' do
          case_body.should include('### Working papers')
        end
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

      it 'orders the sections according to spec' do
        pending 'uhm. What to do about a general text ordering test'
      end
    end
  end

end
