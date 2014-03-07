require 'nokogiri'
require 'cma/case_store'
require 'uri'

module CMA
  module OFT
    BASE_URI = 'http://oft.gov.uk'

    module Mergers
      class Case
        attr_accessor :title, :sector, :original_url

        def base_name
          @base_name ||= URI.parse(original_url).path[1..-1].gsub('/', '-')
        end

        def assets
          []
        end

        def save!
          CMA::CaseStore.instance.save(self)
        end

        def self.load(filename)
          CMA::CaseStore.instance.load(filename)
        end

        def case_type
          'mergers'
        end

        ##
        # Relative to the CaseStore
        def filename
          File.join(case_type, base_name) + '.json'
        end

        def to_json
          {
            'title'        => title,
            'case_type'    => case_type,
            'sector'       => sector,
            'original_url' => original_url,
          }
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
