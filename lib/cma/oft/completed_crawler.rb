require 'cma/crawler'
require 'cma/asset'

module CMA
  module OFT
    ##
    # This crawler only used to link up completed OFT cases to
    # a supplied CC case. Small enough to deal with markets and
    # mergers, which is all it's interested in
    class CompletedCrawler < CMA::Crawler
      MARKETS_WORK = %r{/OFTwork/markets-work/(?!references/?$)(?:references/)?([a-zA-Z0-9\-/]+)/?$}
      MERGERS_WORK = %r{/OFTwork/mergers/((Mergers_Cases|decisions)/[a-zA-Z0-9\-/]+)/?$}
      UNDERTAKINGS = %r{/OFTwork/mergers/register/Initial-undertakings}
      ASSET        = %r{/shared_oft/.*\.pdf}

      INTERESTED_ONLY_IN = [MERGERS_WORK, MARKETS_WORK, UNDERTAKINGS, ASSET]

      def initialize(cc_case)
        @cc_case = cc_case
      end

      def create_or_update_content_for(page)
        page_url = page.url.to_s

        @cc_case.original_urls << page_url unless page_url =~ ASSET
        case
        when page_url =~ MARKETS_WORK
          @cc_case.add_oft_content($1.gsub(%r{/$}, ''), page.doc, '.body-copy')
        when page_url =~ MERGERS_WORK
          @cc_case.add_oft_content($1.gsub(%r{/$}, ''), page.doc, '.intro')
        when page_url =~ UNDERTAKINGS
          @cc_case.add_oft_content('initial-undertakings', page.doc, '.intro')
        when page_url =~ ASSET
          asset = CMA::Asset.new(page_url, @cc_case, page.body, page.headers['content-type'].first)
          asset.save!
          @cc_case.assets << asset
        else
          puts "*** WARN: skipping #{page.url} from #{page.referer}"
        end
      end

      def crawl!(start_url)
        do_crawl(start_url) do |crawl|

          crawl.on_every_page do |page|
            puts "\t#{page.url} <- #{page.referer}"
            create_or_update_content_for(page)
          end

          crawl.focus_crawl do |page|
            next [] if page.doc.nil?

            page.doc.css('.body-copy a').map do |a|
              next unless (href = a['href'])

              if INTERESTED_ONLY_IN.any? { |pattern| pattern =~ href }
                URI(File.join('http://oft.gov.uk', a['href']))
              end
            end.compact
          end
        end
      end

    end
  end
end
