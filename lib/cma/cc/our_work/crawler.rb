require 'cma/crawler'

module CMA
  module CC
    module OurWork
      class Crawler < CMA::Crawler
        CASE = %r{/our-work/directory-of-all-inquiries/[a-z|A-Z|0-9|-]+$}

        INTERESTED_ONLY_IN = [
          CASE
        ]

        def create_or_update_content_for(page)

        end

        def crawl!
          do_crawl('http://www.competition-commission.org.uk/our-work') do |crawl|

            crawl.on_every_page do |page|
              puts "#{page.url} <- #{page.referer}"
              create_or_update_content_for(page)
            end

            crawl.focus_crawl do |page|
              next [] if page.doc.nil?

              page.doc.css('#mainColumn a').map do |a|
                next unless (href = a['href'])

                if INTERESTED_ONLY_IN.any? { |pattern| pattern =~ href }
                  URI(File.join('http://www.competition-commission.org.uk/', a['href']))
                end
              end.compact
            end

          end
        end
      end
    end
  end
end
