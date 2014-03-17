require 'cma/case_store'
require 'cma/cc/our_work/oft_linkage'
require 'cma/oft/completed_crawler'

module CMA
  module CC
    module OurWork
      ##
      # Merge existing CC Cases with corresponding ones in OFT
      class MergeWithOft
        def merge!
          OFT_LINKAGE.each_pair do |cc_url, oft_url|
            CaseStore.instance.find(cc_url).tap do |cc_case|
              puts "****** #{oft_url} for #{cc_url}"
              CMA::OFT::CompletedCrawler.new(cc_case).crawl!(oft_url)
              cc_case.save!
            end
          end
        end
      end

    end
  end
end
