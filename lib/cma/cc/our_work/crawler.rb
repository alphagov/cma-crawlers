require 'cma/crawler'

module CMA
  module CC
    module OurWork
      class Crawler < CMA::Crawler
        def crawl!
          raise NotImplementedError
        end
      end
    end
  end
end
