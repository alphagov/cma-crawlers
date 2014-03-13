require 'anemone'

module CMA
  class Crawler
    MAILTO_LINKS    = %r{mailto:}
    IN_PAGE_ANCHORS = %r{/?#}
    NEWS_AND_UPDATES     = %r{/news-and-updates}

    attr_reader :crawl
    def do_crawl(start_url, options = {})
      Anemone.crawl(start_url, options) do |crawl|
        @crawl = crawl
        yield @crawl
      end
    end

    def with_case(url, from = nil)
      _case = CMA::CaseStore.instance.find(url)
      if _case
        _case.original_urls << from.to_s if from
        yield _case
      else
        puts "*** WARN: case for #{url} not found"
      end
    end

    def with_nearest_case_matching(url, regex, from = nil, &block)
      page = find_nearest_page_matching(url, regex)
      raise ArgumentError, "No page matching #{regex} available for #{url}" if page.nil?
      with_case(page.url.to_s, from, &block)
    end

    ##
    # Use the Anemone page store to find the closest referer in the crawl tree
    # that is a case (or nil if any URL in the chain can't be found)
    def find_nearest_page_matching(url, regex)
      raise ArgumentError,
            'No crawl found. Set @crawl as the first thing in your Anemone.crawl block' if crawl.nil?

      page = @crawl.pages[url]
      return page if page.nil? || page.url.to_s =~ regex

      find_nearest_page_matching(page.referer, regex)
    end
  end
end
