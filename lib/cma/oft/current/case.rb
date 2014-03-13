require 'cma/case'
require 'cma/oft'

module CMA
  module OFT
    module Current
      class Case < CMA::Case
        attr_accessor :summary, :body

        def add_summary(doc)
          self.summary = doc.at_xpath('//div[@class="intro"]/p[2]').content
          save!
        end

        def add_detail(doc)
          doc.dup.at_css('.body-copy').tap do |body_copy|
            %w(div span script p.backtotop p.previouspage).each do |selector|
              body_copy.css(selector).remove
            end

            %w(
              //table/@*
              //a/@target
              //comment()
            ).each do |superfluous_nodes|
              body_copy.xpath(superfluous_nodes).each(&:unlink)
            end

            self.body = Kramdown::Document.new(
              body_copy.inner_html.to_s,
              input: 'html'
            ).to_kramdown

            save!
          end
        end

        def self.from_case_list_row(row)
          raise ArgumentError,
                "row must be a Nokogiri::XML::Node, got: #{row.class}" unless row.is_a?(Nokogiri::XML::Node)
          self.new.tap do |c|
            case_link = row.at_css('td a')

            c.title        = case_link.text.split("\r").first
            c.original_url = File.join(BASE_URI, case_link['href'])
            /Sector.+\r\n(?<sector_text>.*)/m =~ case_link.text
            c.sector = SECTOR_MAPPINGS[sector_text] || "Missing mapping for '#{c.sector}'"
          end
        end
      end
    end
  end
end
