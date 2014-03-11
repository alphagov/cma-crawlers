require 'nokogiri'
require 'kramdown'
require 'cma/case_store'
require 'uri'
require 'active_model'

module CMA
  module OFT
    BASE_URI = 'http://oft.gov.uk'

    module Mergers
      class Case
        include ActiveModel::Serializers::JSON

        attr_accessor :title, :sector, :original_url,
                      :invitation_to_comment, :decision, :initial_undertakings

        attr_writer :assets

        def assets
          @assets ||= []
        end

        def base_name
          @base_name ||= CaseStore.base_name(original_url)
        end

        def save!
          CMA::CaseStore.instance.save(self)
        end

        def self.load(filename)
          CMA::CaseStore.instance.load(filename)
        end

        def case_state
          'open'
        end

        def case_type
          'mergers'
        end

        def filename
          base_name + '.json'
        end

        def attributes
          instance_values
        end

        def serializable_hash(options={})
          super.tap do |hash|
            hash.delete('base_name')
            hash['case_type'] = case_type
            hash['case_state'] = case_state
          end
        end

        def attributes=(hash)
          hash.each_pair do |k, v|
            setter = "#{k}="
            self.send(setter, v) if respond_to?(setter)
          end
        end

        def add_details_from_case(doc, setter)
          doc.at_css('div.intro').dup.tap do |intro|
            %w(div span script a p.backtotop).each { |tag| intro.css(tag).remove }

            setter = (setter.to_s + '=').to_sym
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
            c.sector       = row.at_xpath('td[2]').text.strip
          end
        end
      end
    end
  end
end
