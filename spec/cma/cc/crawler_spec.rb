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
        'http://www.competition-commission.org.uk/assets/anything.pdf'.
        should match(Crawler::ASSET)
      end
      specify do
        'http://www.competition-commission.org.uk/our-work/directory-of-all-inquiries/aggregates-cement-ready-mix-concrete/news-releases'.
        should match(Crawler::SUBPAGE)
      end

    end
  end
end
