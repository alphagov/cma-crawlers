require 'anemone'
require 'cma/asset'
require 'cma/oft/markets/case'
require 'cma/oft/markets/case_list'
require 'cma/crawler'

module CMA
  module OFT
    module Markets
      class Crawler < CMA::Crawler
        # Significant things we're parsing
        CASE_INDEX         = %r{/OFTwork/oft-current-cases/?$}
        CASE               = %r{
          /OFTwork/oft-current-cases/(?:markets-work(?!/personal)|market-studies)-?20[0-9]{2}/[a-z|A-Z|0-9|-]+/?$
        }x
        CASE_DETAIL        = %r{/OFTwork/markets-work/(?:othermarketswork/)?(?!othermarketswork)[a-z|A-Z|0-9|-]+/?$}
        ASSET              = %r{(?<!Brie1)\.pdf$} # Delicious Brie1 actually a briefing note

        INTERESTED_ONLY_IN = [
          CASE_INDEX, CASE, CASE_DETAIL, ASSET
        ]

        ICT_CFI  = %r{ICT-CFI}
        PERSONAL = %r{/OFTwork/markets-work/personal}
        EXPLICITLY_SKIP = [
          ICT_CFI, PERSONAL
        ]

        def create_or_update_content_for(page)
          page_url = page.url.to_s
          case
          when page_url =~ CASE_INDEX
            CMA::OFT::Markets::CaseList.from_html(page.doc).save!
          when page_url =~ CASE
            with_case(page.url, page_url) do |_case|
              _case.add_summary(page.doc)
            end
          when page_url =~ CASE_DETAIL
            with_case(page.referer, page_url) do |_case|
              _case.add_detail(page.doc)
            end
          when page_url =~ ASSET
            with_nearest_case_matching(page.referer, CASE) do |_case|
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
          do_crawl('http://oft.gov.uk/OFTwork/oft-current-cases/') do |crawl|

            crawl.on_every_page do |page|
              puts "#{page.url} <- #{page.referer}"
              create_or_update_content_for(page)
            end

            crawl.focus_crawl do |page|
              next [] if page.doc.nil?

              page.doc.css('.body-copy a').map do |a|
                next unless (href = a['href'])

                if(
                  INTERESTED_ONLY_IN.any? { |pattern| pattern =~ href } &&
                  EXPLICITLY_SKIP.none? {|pattern| pattern =~ href}
                )
                  URI(File.join('http://oft.gov.uk', a['href']))
                end
              end.compact
            end

            # External links that for some reason Anemone is passing on
            crawl.skip_links_like [
                                    /catribunal\.org\.uk/,
                                    /www\.gov\.uk/,
                                    /legislation\.gov\.uk/,
                                    /lease-advice\.org/,
                                    /adviceguide\.org/,
                                    /citizensadvice\.org/
                                  ]
          end
        end

      end
    end
  end
end



