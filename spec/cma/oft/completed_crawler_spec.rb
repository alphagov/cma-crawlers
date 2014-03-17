require 'spec_helper'
require 'cma/oft/completed_crawler'

module CMA::OFT
  describe CompletedCrawler do
    describe 'what should match what' do
      example 'markets work' do
        'http://www.oft.gov.uk/OFTwork/markets-work/references/aggregates-MIR'.
          should match(CompletedCrawler::MARKETS_WORK)
      end
      example 'not markets work' do
        'http://www.oft.gov.uk/OFTwork/markets-work'.
          should_not match(CompletedCrawler::MARKETS_WORK)
      end
      example 'not markets work' do
        'http://www.oft.gov.uk/OFTwork/markets-work/references'.
          should_not match(CompletedCrawler::MARKETS_WORK)
      end
      example 'asset' do
        'http://www.oft.gov.uk/shared_oft/market-studies/oft1358ref.pdf'.
          should match(CompletedCrawler::ASSET)
      end
      example 'mergers work' do
        'http://oft.gov.uk/OFTwork/mergers/decisions/2013/tradebe' =~
          CompletedCrawler::MERGERS_WORK
        $1.should == 'decisions/2013/tradebe'
      end
      example 'mergers work' do
        'http://www.oft.gov.uk/OFTwork/mergers/Mergers_Cases/2013/Tradebe' =~
          CompletedCrawler::MERGERS_WORK
        $1.should == 'Mergers_Cases/2013/Tradebe'
      end
    end
  end
end
