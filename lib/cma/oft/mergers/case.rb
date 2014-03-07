require 'nokogiri'
require 'kramdown'
require 'cma/case_store'
require 'uri'

module CMA
  module OFT
    BASE_URI = 'http://oft.gov.uk'

    module Mergers
      class Case
        attr_accessor :title, :sector, :original_url, :invitation_to_comment

        def base_name
          @base_name ||= CaseStore.base_name(original_url)
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

        def state
          'open'
        end

        def case_type
          'mergers'
        end

        def filename
          base_name + '.json'
        end

        def to_json
          {
            'title'                 => title,
            'case_type'             => case_type,
            'sector'                => sector,
            'original_url'          => original_url,
            'invitation_to_comment' => invitation_to_comment
          }
        end

        def add_details_from_case(doc)
          doc.at_css('div.intro').tap do |intro|
            %w(div span script a p.backtotop).each { |tag| intro.css(tag).remove }

            self.invitation_to_comment = Kramdown::Document.new(
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
            c.sector       = row.at_xpath('td[2]').text.strip
          end
        end
      end
    end
  end
end
