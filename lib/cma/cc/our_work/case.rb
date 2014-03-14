module CMA
  module CC
    module OurWork
      class Case < CMA::Case
        attr_accessor :date_of_referral, :statutory_deadline

        # body types that will need body generation/ordering later
        attr_accessor :core_documents

        def case_type
          'unknown'
        end

        def add_case_detail(doc)
          self.title              = doc.at_css('#mainColumn h1').text
          self.date_of_referral   = parse_date_at_xpath(
            doc, '//div[@id="mainColumn"]/h1/following-sibling::p/text()[2]')
          self.statutory_deadline = parse_date_at_xpath(
            doc, '//div[@id="mainColumn"]/h1/following-sibling::p/text()[3]')

          add_markdown_detail(doc, :core_documents)
        end

        def add_markdown_detail(doc, attr)
          doc.dup.at_css('#mainColumn').tap do |markup|
            # Simple stuff
            %w(div img hr script ul#pageOptions a#accesskey-skip).each { |tag| markup.css(tag).remove }

            # Stuff CSS can't handle
            %w(
              //a[contains(text\(\),'Print')]
              //a[contains(text\(\),'RSS')]
              //span[not(contains(@class,'mediaLinkText'))]
              //a/@target
              //a/@rel
              //@class
              //comment()
            ).each do |superfluous_nodes|
              markup.xpath(superfluous_nodes).each(&:unlink)
            end

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

            setter = (attr.to_s + '=').to_sym
            send setter, Kramdown::Document.new(
              markup.inner_html.to_s,
              input: 'html'
            ).to_kramdown

            save!
          end
        end


        def parse_date_at_xpath(doc, xpath)
          Date.strptime(
            doc.at_xpath(xpath).text.strip,
            '%d.%m.%y'
          )
        end

        def self.from_link(node)
          Case.new.tap do |c|
            c.original_url = node['href']
            c.title = node.text
          end
        end
      end
    end
  end
end
