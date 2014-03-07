require 'nokogiri'

module CMA
  module OFT
    BASE_URI = 'http://oft.gov.uk'

    module Mergers
      class Case
        attr_accessor :title, :sector, :original_url

        def assets
          []
        end

        def self.from_case_list_row(row)
          raise ArgumentError,
                "row must be a Nokogiri::XML::Node, got: #{row.class}" unless row.is_a?(Nokogiri::XML::Node)
          Case.new.tap do |c|
            case_link = row.at_css('td a')

            c.title        = case_link.text
            c.original_url = File.join(BASE_URI, case_link['href'])
            c.sector       = row.at_xpath('td[2]').text.strip
          end
        end
      end
    end
  end
end
