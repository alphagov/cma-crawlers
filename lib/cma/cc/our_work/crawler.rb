require 'cma/crawler'
require 'cma/asset'
require 'cma/cc/our_work/case_list'

module CMA
  module CC
    module OurWork
      class Crawler < CMA::Crawler
        CASE_INDEX        = %r{/our-work/?$}
        CASE              = %r{/our-work/directory-of-all-inquiries/[a-z|A-Z|0-9|-]+$}
        SUBPAGE           = %r{/our-work/directory-of-all-inquiries/[a-z|A-Z|0-9|-]+/[a-z|A-Z|0-9|-]+(?:/[a-z|A-Z|0-9|-]+)?/?$}
        ASSET             = %r{/assets/.*\.pdf$}

        INTERESTED_ONLY_IN = [
          CASE,
          SUBPAGE,
          ASSET
        ]

        def create_or_update_content_for(page)
          page_url = page.url.to_s
          case
          when page_url =~ CASE_INDEX
            CMA::CC::OurWork::CaseList.from_html(page.doc).save!
          when page_url =~ CASE
            with_case(page_url, page_url) do |c|
              c.add_case_detail(page.doc)
            end
          when page_url =~ SUBPAGE
            with_nearest_case_matching(page.referer, CASE, page_url) do |c|
              c.add_markdown_detail(page.doc, case_relative_path(page_url), url: page_url)
            end
          when page_url =~ ASSET
            with_nearest_case_matching(page.referer, CASE) do |_case|
              asset = CMA::Asset.new(page.url.to_s, _case, page.body, page.headers['content-type'].first)
              asset.save!
              _case.assets << asset
              _case.save!
            end
          else
            puts "WARN: Skipping #{page_url}"
          end
        end

        SUBPAGE_PARSE = %r{/our-work/directory-of-all-inquiries/[a-z|A-Z|0-9|-]+/([a-z|A-Z|0-9|-]+(/[a-z|A-Z|0-9|-]+)?)/?$}
        ##
        # Given a URL like http://cc.org.uk/our-work/directory-of-all-inquiries/aggregates/some-page/another-page,
        # return a path relative to the case, like some-page/another-page,
        # or raise +ArgumentError+ if the URL is not for a SUBPAGE
        def case_relative_path(url)
          url = url.to_s
          raise ArgumentError unless url =~ SUBPAGE_PARSE
          $1.downcase
        end

        ##
        # Context-sensitive set of links per page
        def link_nodes_for(page)
          nodes  = page.doc.css('#mainColumn a')
          if [CASE, SUBPAGE].any? { |match| page.url.to_s =~ match }
            nodes += page.doc.css('#leftNavigation a')
          end
          nodes
        end

        def normalize_uri(str)
          URI.parse(str.gsub(' ', '%20'))
        end

        def crawl!
          do_crawl('http://www.competition-commission.org.uk/our-work') do |crawl|

            crawl.on_every_page do |page|
              puts "#{page.url}#{'<- ' if page.referer}#{page.referer}"
              create_or_update_content_for(page)
            end

            crawl.focus_crawl do |page|
              next [] if page.doc.nil?

              link_nodes_for(page).map do |a|
                next unless (href = a['href'])

                if INTERESTED_ONLY_IN.any? { |pattern| pattern =~ href }
                  begin
                    normalize_uri(File.join('http://www.competition-commission.org.uk/', href))
                  rescue URI::InvalidURIError
                    puts "MALFORMED URL: #{href} <- #{page.url}"
                  end
                end
              end.compact
            end

          end
        end
      end
    end
  end
end
