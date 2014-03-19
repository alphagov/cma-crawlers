require 'cma/case_store'
require 'kramdown'

module CMA
  module CC
    class BodyGenerator
      def case_store
        CMA::CaseStore.instance
      end

      def cases
        Dir[File.join(case_store.location, 'our-work*.json')].map do |f|
          case_store.load(f)
        end
      end

      def generate_body_for!(_case)
        _case.body = "## Phase 2\n\n"

        _case.body << "Date of referral:  #{reformat_date(_case.date_of_referral)}\n"
        _case.body <<
          "Statutory deadline:  #{reformat_date(_case.statutory_deadline)}\n" if _case.statutory_deadline
        _case.body << "\n"

        append_single_sections(
          %w(
            core_documents
            remittal
            undertakings-and-order
            final_report
            provisional-final-report
            annotated-issues-statement
          ),
          _case
        )

        append_subsections(
          %w(
            evidence
            analysis
          ),
          _case
        )

        append_single_sections(
          %w(
            news-releases
            news-releases-announcements
          ),
          _case
        )

        append_oft_sections(_case)
      end

      def append_subsections(subsection_names, _case )
        subsection_names.each do |prefix|
          in_order_subsections = _case.markup_sections.keys.select do |section_name|
            section_name =~ Regexp.new("^#{prefix}/")
          end

          in_order_subsections.each do |section_name|
            _case.markup_sections[section_name].tap do |content|
              _case.body << transformed_content(content, header_offset: 1)
            end
          end
        end
      end

      def append_bodies(_case, bodies, options = { header_offset: 1 })
        bodies.each do |section_body|
          _case.body << transformed_content(section_body, options)
        end
      end

      def append_single_sections(section_names, _case)
        bodies = section_names.map { |cc_section_name| _case.markup_sections[cc_section_name] }.compact

        append_bodies(_case, bodies)
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

      def transformed_content(source, options)
        html = Nokogiri::HTML(Kramdown::Document.new(source, options).to_html)
        transform_tables_to_lists!(html)
        Kramdown::Document.new(html.to_s, options.merge(input: :html)).to_kramdown
      end

      def reformat_date(value)
        Date.strptime(value, '%Y-%m-%d').strftime('%d/%m/%Y')
      end

      def append_oft_sections(_case)
        bodies = _case.markup_sections.inject([]) do |bodies, name_content|
          bodies << name_content.last if name_content.first =~ %r{OFT/}
          bodies
        end

        if bodies.any?
          _case.body << "\n## Phase 1\n"

          append_bodies(_case, bodies, header_offset: 2)
        end
      end

      def generate!
        cases.each do |_case|
          puts "Generating body for #{_case.filename}"
          generate_body_for!(_case)
          case_store.save(_case)
        end
      end
    end
  end
end
