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
              _case.body << Kramdown::Document.new(content, header_offset: 1).to_kramdown
            end
          end
        end
      end

      def append_bodies(_case, bodies, options = { header_offset: 1 })
        bodies.each do |section_body|
          Kramdown::Document.new(
            section_body, header_offset: options[:header_offset]
          ).tap do |tree|
            _case.body << tree.to_kramdown
          end
        end
      end

      def append_single_sections(section_names, _case)
        bodies = section_names.map { |cc_section_name| _case.markup_sections[cc_section_name] }.compact

        append_bodies(_case, bodies)
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
