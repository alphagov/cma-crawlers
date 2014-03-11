require 'cma/case'

module CMA
  module OFT
    BASE_URI = 'http://oft.gov.uk'

    module Competition
      class Case < CMA::Case
        def case_type
          'ca98-and-civil-cartels'
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
