require 'cma/case'
require 'cma/oft/sector_mappings'

module CMA
  module OFT
    BASE_URI = 'http://oft.gov.uk'

    module Mergers
      class Case < CMA::Case
        attr_accessor :invitation_to_comment, :decision, :initial_undertakings

        def case_type
          'mergers'
        end

        def add_details_from_case(doc, attr)
          doc.at_css('div.intro').dup.tap do |intro|
            %w(div span script a p.backtotop).each { |tag| intro.css(tag).remove }

            setter = (attr.to_s + '=').to_sym
            send setter, Kramdown::Document.new(
              intro.inner_html.to_s,
              input: 'html'
            ).to_kramdown

            save!
          end
        end

        def self.from_case_list_row(row)
          raise ArgumentError,
                "row must be a Nokogiri::XML::Node, got: #{row.class}" unless row.is_a?(Nokogiri::XML::Node)
          Case.new.tap do |c|
            case_link = row.at_css('td a')

            c.title        = case_link.text
            c.original_url = File.join(BASE_URI, case_link['href'])
            sector_text    = row.at_xpath('td[2]').text.strip
            c.sector       = SECTOR_MAPPINGS[sector_text] || "Missing mapping for '#{c.sector}'"
          end
        end
      end
    end
  end
end
