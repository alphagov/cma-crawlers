require 'cma/asset'

module CMA
  module OFT
    module Mergers
      class Crawler
        CASE_INDEX        = %r{/OFTwork/mergers/Mergers_Cases/?$}
        CASE              = %r{/OFTwork/mergers/Mergers_Cases/20[0-9]{2}/[a-z|A-Z|0-9]+}
        CASE_UNDERTAKINGS = %r{/OFTwork/mergers/register/Initial-undertakings}
        CASE_DECISION     = %r{/OFTwork/mergers/decisions/20[0-9]{2}/[a-z|A-Z|0-9]+}
        ASSET             = %r{\.pdf$}

        MERGERS_INDEX_PAGES  = %r{/OFTwork/mergers/Mergers_Cases/20[0-9]{2}/?$}
        MERGERS_FILTER_PAGES = %r{\?caseByCompany=}
        MERGERS_FTA          = %r{mergers_fta}
        MAILTO_LINKS         = %r{mailto:}
        IN_PAGE_ANCHORS      = %r{/?#}

        SKIP_LINKS_LIKE = [
          MERGERS_INDEX_PAGES,
          MERGERS_FILTER_PAGES,
          MERGERS_FTA,
          MAILTO_LINKS,
          IN_PAGE_ANCHORS
        ]

        def create_or_update_content_for(page)
          page_url = page.url.to_s
          case
          when page_url =~ CASE_INDEX
            CMA::OFT::Mergers::CaseList.from_html(page.doc).save!
          when page_url =~ CASE
            with_case(page.url) do  |_case|
              _case.add_details_from_case(page.doc, :invitation_to_comment)
            end
          when page_url =~ CASE_UNDERTAKINGS
            with_case(page.referer) do  |_case|
              _case.add_details_from_case(page.doc, :initial_undertakings)
            end
          when page_url =~ CASE_DECISION
            puts "#{page.url.path} parse decision"
          when page_url =~ ASSET
            with_nearest_case_matching(page.referer, CASE) do |_case|
              asset = CMA::Asset.new(page.url.to_s, _case, page.body, page.headers['content-type'].first)
              asset.save!
              _case.assets << asset
              _case.save!
            end
          else
            puts "*** WARN: skipping #{page.url}"
          end
        end

        def crawl
          @crawl
        end

        def with_case(url)
          _case = CMA::CaseStore.instance.find(url)
          if _case
            yield _case
          else
            puts "*** WARN: case for #{url} not found"
          end
        end

        def with_nearest_case_matching(url, regex = CASE)
          page = find_nearest_page_matching(url, regex)
          raise ArgumentError, "No page available for #{url}" if page.nil?
          CMA::CaseStore.instance.find(page.url.to_s).tap do |_case|
            yield _case unless _case.nil?
          end
        end

        ##
        # Use the Anemone page store to find the closest referer in the crawl tree
        # that is a case (or nil if any URL in the chain can't be found)
        def find_nearest_page_matching(url, regex = CASE)
          page = @crawl.pages[url]
          return page if page.nil? || page.url.to_s =~ regex

          find_nearest_page_matching(page.referer)
        end

        def crawl!
          Anemone.crawl('http://oft.gov.uk/OFTwork/mergers/Mergers_Cases') do |crawl|
            @crawl = crawl

            crawl.on_every_page do |page|
              puts page.url
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
          end
        end

      end
    end
  end
end


