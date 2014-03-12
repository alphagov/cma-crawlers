require 'cma/case'
require 'cma/oft'

module CMA
  module OFT
    module Competition
      class Case < CMA::Case
        attr_accessor :summary

        def case_type
          'ca98-and-civil-cartels'
        end

        def add_summary(doc)
          self.summary = doc.at_xpath('//div[@class="intro"]/p[2]').content
          save!
        end

        def self.from_case_list_row(row)
          raise ArgumentError,
                "row must be a Nokogiri::XML::Node, got: #{row.class}" unless row.is_a?(Nokogiri::XML::Node)
          Case.new.tap do |c|
            case_link = row.at_css('td a')

            c.title        = case_link.text.split("\r").first
            c.original_url = File.join(BASE_URI, case_link['href'])
            sector_text    = case_link.text.split("\r")[6].strip
            c.sector       = SECTOR_MAPPINGS[sector_text] || "Missing mapping for '#{c.sector}'"
          end
        end
      end
    end
  end
end
