require 'cma/markup_helpers'
require 'kramdown/converter/kramdown_patched'

module CMA
  module CC
    module OurWork
      class Case < CMA::Case
        BASE_URI = 'http://www.competition-commission.org.uk'

        attr_accessor :case_type, :date_of_referral, :statutory_deadline

        # body types that will need body generation/ordering later
        attr_writer :markup_sections
        def markup_sections
          @markup_sections ||= {}
        end

        def add_case_detail(doc)
          self.title              = doc.at_css('#mainColumn h1').text
          self.date_of_referral   = parse_date_at_xpath(
            doc, [possible_date_position_1(2), possible_date_position_2(2)])
          self.statutory_deadline = parse_date_at_xpath(
            doc, [possible_date_position_1(3), possible_date_position_2(3)])

          add_markdown_detail(doc, 'core_documents')
        end

        # Dates could be here
        def possible_date_position_1(index)
          "//div[@id='mainColumn']/h1/following-sibling::p/text()[#{index}]"
        end

        # Or here, depending on value of $WTFICANTEVEN
        def possible_date_position_2(index)
          "//div[@id='mainColumn']/h1/following-sibling::div/p[1]/text()[#{index}]"
        end

        def add_oft_content(markup_sections_key, doc, body_selector)
          doc.dup.at_css(body_selector).tap do |body_copy|
            %w(div span script p.backtotop p.previouspage).each do |selector|
              body_copy.css(selector).remove
            end

            %w(
              //table/@*
              //a/@target
              //a[@name]
              //comment()
            ).each do |superfluous_nodes|
              body_copy.xpath(superfluous_nodes).each(&:unlink)
            end

            body_copy.make_relative_links_absolute!(CMA::OFT::BASE_URI)

            markup_sections["OFT/#{markup_sections_key}"] = Kramdown::Document.new(
              body_copy.inner_html.to_s,
              input: 'html'
            ).to_kramdown.gsub(/\{:.+?}/m, '')
          end
        end

        def transform_tables_to_lists!(node)
          tables = node.xpath('.//table')
          return node unless tables.length > 0

          li_nodes = []

          tables.each do |table|
            table.xpath('tbody/tr').each do |tr|
              tr.remove and next unless tr.xpath('td').any? # There are th's in tbody...

              p_or_links     = tr.xpath('td[1]//p|td[1]//a')
              date_published = tr.at_xpath('td[2]').try(:text)

              next unless p_or_links.any?

              p_or_links.each do |link|
                if link.name == 'a' && date_published
                  # \u00a0 == &nbsp;
                  link.content = link.text.sub(/\)(?:\s|\u00a0)+$/, ", #{date_published})")
                end

                Nokogiri::XML::Node.new('li', node.document).tap do |li|
                  li << link
                  li_nodes << li
                end
              end
            end

            Nokogiri::XML::Node.new('ul', node.document).tap do |replacement_list|
              li_nodes.each { |li| replacement_list << li }
              table.add_next_sibling(replacement_list)
              table.remove
            end
          end
        end

        def add_markdown_detail(doc, markup_sections_path, options = {url: :unknown})
          doc.dup.at_css('#mainColumn').tap do |markup|
            # Simple stuff
            %w(div img script ul#pageOptions a#accesskey-skip).each { |tag| markup.css(tag).remove }

            # Move the thing that should just be li > a out from under its SiteCore
            # styling. Way to MsoNormal
            markup.css('li p.MsoNormal span a').each do |link|
              link.parent = link.at_xpath('ancestor::li')
            end

            transform_tables_to_lists!(markup)

            # Stuff CSS can't handle, and stuff Kramdown can't either
            %w(
              //a[contains(text\(\),'Print')]
              //a[contains(text\(\),'RSS')]
              //span[not(contains(@class,'mediaLinkText'))]
              //a/@target
              //a/@name
              //a/@shape
              //a/@rel
              //@class
              //@style
              //comment()
            ).each do |superfluous_nodes|
              markup.xpath(superfluous_nodes).each(&:unlink)
            end

            markup.make_relative_links_absolute!(BASE_URI)

            markup.xpath('.//h2[1]/preceding-sibling::*').each(&:remove)

            # Move text in leftover spans that were .mediaLinkText
            # to the link as a parent
            markup.xpath('.//span').each do |span|
              span.at_xpath('./text()').parent = span.parent
              span.remove
            end

            # Deal with <strong> tags that end in space
            # https://github.com/gettalong/kramdown/issues/65
            markup.xpath('.//strong').each do |strong|
              strong.content = strong.content.strip
            end

            markup_sections[markup_sections_path] =
              Kramdown::Document.new(
              markup.inner_html.to_s,
                input: 'html'
              ).to_kramdown.gsub(/\{:.+?}/m, '')
          end
        end

        def parse_date_at_xpath(doc, try_xpath)
          xpath = try_xpath.find { |xpath| doc.at_xpath(xpath) }
          return if (date_node = doc.at_xpath(xpath)).nil?
          date_node.text =~ /([0-9]{2}\.[0-9]{2}\.[0-9]{2})/
          Date.strptime($1, '%d.%m.%y') if xpath
        end

        TITLES_TO_CASE_TYPES = {
          'Market investigations' => 'markets',
          'Merger inquiries' => 'mergers',
          'Regulatory references and appeals' => 'regulatory-references-and-appeals',
          'Reviews of Orders and undertakings' => 'review-of-orders-and-undertakings',
        }
        def self.from_link(node)
          Case.new.tap do |c|
            c.original_url = File.join(BASE_URI, node['href'])
            c.title = node.text

            # Find nearest h3, resolve to case_type
            c.case_type = TITLES_TO_CASE_TYPES[
              node.at_xpath('./ancestor::div[2]/preceding-sibling::h3[1]').text
            ]
          end
        end
      end
    end
  end
end
