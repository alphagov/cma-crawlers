require 'cma/asset'
require 'cma/oft/competition/case'
require 'cma/oft/competition/case_list'
require 'cma/oft/crawler'

module CMA
  module OFT
    module Competition
      class Crawler < CMA::OFT::Crawler
        CASE_INDEX         = %r{/OFTwork/oft-current-cases/?$}
        CASE               = %r{/OFTwork/oft-current-cases/competition-case-list-20[0-9]{2}/[a-z|A-Z|0-9|-]+/?$}
        CASE_DETAIL        = %r{/OFTwork/competition-act-and-cartels/(?:ca98-current|criminal-cartels-current)/[a-z|A-Z|0-9]+/?}
        CASE_LISTS_BY_YEAR = %r{/OFTwork/oft-current-cases/[a-z|-]+-20[0-9]{2}/?$}
        NEWS_AND_UPDATES   = %r{/news-and-updates}
        ABOUT_THE_OFT      = %r{/about-the-oft}
        SHARED_OFT         = %r{/shared_oft}
        ASSET              = %r{\.pdf$}

        COMPETITION_INDEX_PAGES  = %r{/OFTwork/mergers/Mergers_Cases/20[0-9]{2}/?$}

        CONSUMER_CASES   = %r{/OFTwork/oft-current-cases/consumer-case-list-}
        MARKETS_CASES    = %r{/OFTwork/(?:oft-current-cases/market|markets-work)}
        CARTELS_CURRENT  = %r{/OFTwork/competition-act-and-cartels/(?:ca98-current|criminal-cartels-current)/?$}
        EUROPA           = %r{europa\.eu} # don't know why Anemone is passing externals. Skip!

        SKIP_LINKS_LIKE = [
          CONSUMER_CASES,
          MARKETS_CASES,
          COMPETITION_INDEX_PAGES,
          CARTELS_CURRENT,
          CASE_LISTS_BY_YEAR,
          SHARED_OFT,
          NEWS_AND_UPDATES,
          ABOUT_THE_OFT,
          EUROPA,
          MAILTO_LINKS,
          IN_PAGE_ANCHORS
        ]

        def create_or_update_content_for(page)
          page_url = page.url.to_s
          case
          when page_url =~ CASE_INDEX
            CMA::OFT::Competition::CaseList.from_html(page.doc).save!
          when page_url =~ CASE
            with_case(page.url) do |_case|
              _case.add_summary(page.doc)
            end
          when page_url =~ CASE_DETAIL
            with_case(page.referer, page_url) do |_case|
              _case.add_detail(page.doc)
            end
          when page_url =~ ASSET
            # There are probably no assets, but I'm not betting against one
            # turning up while we're writing the crawler.
            with_nearest_case_matching(page.referer, CASE, page_url) do |_case|
              asset = CMA::Asset.new(page.url.to_s, _case, page.body, page.headers['content-type'].first)
              asset.save!
              _case.assets << asset
              _case.save!
            end
          else
            puts "*** WARN: skipping #{page.url} from #{page.referer}"
          end
        end

        def crawl!
          Anemone.crawl('http://oft.gov.uk/OFTwork/oft-current-cases/') do |crawl|
            @crawl = crawl

            crawl.on_every_page do |page|
              puts "#{page.url} <- #{page.referer}"
              create_or_update_content_for(page)
            end

            crawl.focus_crawl do |page|
              next [] if page.doc.nil?

              page.doc.css('.body-copy a').map do |a|
                next unless (href = a['href'])

                unless SKIP_LINKS_LIKE.any? { |pattern| pattern =~ href }
                  URI(File.join('http://oft.gov.uk', a['href']))
                end
              end.compact
            end

            # External links that for some reason Anemone is passing on
            crawl.skip_links_like [
                                    /catribunal\.org\.uk/,
                                    /www\.gov\.uk/
                                  ]
          end
        end

      end
    end
  end
end



