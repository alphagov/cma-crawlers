require 'cma/cc/our_work/case'

module CMA
  module CC
    module OurWork
      class CaseList
        include Enumerable

        def initialize(doc)
          @doc = doc
        end

        def case_xpath
          '//div[@id="mainColumn"]/div/div/p/a'\
          '[contains(@href, "/our-work/directory-of-all-inquiries/")]'
        end

        def cases
          @cases ||= begin
            case_links = @doc.xpath(case_xpath)
            case_links.map { |link| Case.from_link(link) }
          end
        end

        def each
          cases.each { |c| yield c }
        end

        def save!
          cases.each(&:save!)
        end

        def self.from_html(html)
          self.new(html)
        end
      end
    end
  end
end
