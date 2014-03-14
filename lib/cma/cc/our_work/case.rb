module CMA
  module CC
    module OurWork
      class Case < CMA::Case
        BASE_URI = 'http://www.competition-commission.org.uk'

        attr_accessor :date_of_referral, :statutory_deadline

        # body types that will need body generation/ordering later
        attr_accessor :core_documents,
                      :annotated_issues_statement,
                      :news_releases_and_announcements,
                      :analysis,
                      :evidence,
                      :provisional_findings_report,
                      :final_report,
                      :provisional_final_report

        def case_type
          'unknown'
        end

        def add_case_detail(doc)
          self.title              = doc.at_css('#mainColumn h1').text
          self.date_of_referral   = parse_date_at_xpath(
            doc, [possible_date_position_1(2), possible_date_position_2(2)])
          self.statutory_deadline = parse_date_at_xpath(
            doc, [possible_date_position_1(3), possible_date_position_2(3)])

          add_markdown_detail(doc, :core_documents)
        end

        # Dates could be here
        def possible_date_position_1(index)
          "//div[@id='mainColumn']/h1/following-sibling::p/text()[#{index}]"
        end

        # Or here, depending on value of $WTFICANTEVEN
        def possible_date_position_2(index)
          "//div[@id='mainColumn']/h1/following-sibling::div/p[1]/text()[#{index}]"
        end

        def add_markdown_detail(doc, attr)
          doc.dup.at_css('#mainColumn').tap do |markup|
            # Simple stuff
            %w(div img hr script ul#pageOptions a#accesskey-skip).each { |tag| markup.css(tag).remove }

            # Stuff CSS can't handle, and stuff Kramdown can't either
            %w(
              //a[contains(text\(\),'Print')]
              //a[contains(text\(\),'RSS')]
              //span[not(contains(@class,'mediaLinkText'))]
              //a/@target
              //a/@name
              //a/@rel
              //@class
              //@style
              //td/@valign
              //thead
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

        def parse_date_at_xpath(doc, try_xpath)
          xpath = try_xpath.find { |xpath| doc.at_xpath(xpath) }
          return if (date_node = doc.at_xpath(xpath)).nil?
          date_node.text =~ /([0-9]{2}\.[0-9]{2}\.[0-9]{2})/
          Date.strptime($1, '%d.%m.%y') if xpath
        end

        def self.from_link(node)
          Case.new.tap do |c|
            c.original_url = File.join(BASE_URI, node['href'])
            c.title = node.text
          end
        end

        ##
        # Return the attr that a particular URL should be setting markdown for
        def self.attr_for_url(uri)
          uri = URI.parse(uri) unless uri.is_a?(URI)

          paths = uri.path.split('/')
          raise ArgumentError, "#{uri.path} not a case subpage" if
            paths[2] != 'directory-of-all-inquiries' || paths.length <= 3
          paths.slice!(0..3)

          paths.length == 2 ?
            [paths.first.underscore.to_sym, paths.last] :
            paths.first.underscore.to_sym
        end
      end
    end
  end
end
