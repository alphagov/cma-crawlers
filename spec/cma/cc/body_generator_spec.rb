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
    end
  end

end
