require 'spec_helper'
require 'cma/cc/our_work/crawler'

module CMA::CC::OurWork
  describe Crawler do
    describe 'what should match what' do
      specify do
        'http://www.competition-commission.org.uk/our-work/directory-of-all-inquiries/tradebe-sita'.
          should match(Crawler::CASE)
      end
      specify do
        'http://www.competition-commission.org.uk/our-work/directory-of-all-inquiries/tradebe-sita/news-releases'.
        should match(Crawler::SUBPAGE)
      end
      specify do
        'http://www.competition-commission.org.uk/our-work/directory-of-all-inquiries/aggregates-cement-ready-mix-concrete/news-releases'.
          should match(Crawler::SUBPAGE)
      end
      specify do
        'http://www.competition-commission.org.uk/our-work/directory-of-all-inquiries/aggregates-cement-ready-mix-concrete/evidence/summaries-of-hearings-held-with-parties'.
          should match(Crawler::SUBPAGE)
      end
      specify do
        'http://www.competition-commission.org.uk/assets/anything.pdf'.
        should match(Crawler::ASSET)
      end
    end

    describe '.case_relative_path' do
      subject { Crawler.new.case_relative_path(url) }
      context 'when not a SUBPAGE' do
        let(:url) { 'http://some.host/our-work/directory-of-all-inquiries/aggregates' }
        it 'raises an error' do
          expect { Crawler.new.case_relative_path(url) }.to raise_error(ArgumentError)
        end
      end

      context 'a first-level SUBPAGE' do
        let(:url) { 'http://some.host/our-work/directory-of-all-inquiries/aggregates/news' }
        it { should eql 'news' }
      end
      context 'a second-level SUBPAGE' do
        let(:url) { 'http://www.competition-commission.org.uk/our-work/directory-of-all-inquiries/cineworld-city-screen/Evidence/initial-submissions' }
        it { should eql 'evidence/initial-submissions' }
      end

    end
  end
end
