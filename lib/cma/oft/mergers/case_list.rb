require 'cma/oft/mergers/case'

module CMA
  module OFT
    module Mergers
      class CaseList
        include Enumerable

        def initialize(doc)
          @doc = doc
        end

        def cases
          @cases ||= begin
            case_rows = @doc.xpath('//table/tr')
            case_rows.map { |row| Case.from_case_list_row(row) }
          end
        end

        def each
          cases.each
        end

        def save!
          cases.each(&:save!)
        end

        def self.from_html(html)
          CaseList.new(html)
        end
      end
    end
  end
end
