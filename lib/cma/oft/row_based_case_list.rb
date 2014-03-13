require 'active_support/concern'

module CMA
  module OFT
    module RowBasedCaseList
      extend ActiveSupport::Concern

      included do
        include Enumerable
      end

      def initialize(doc)
        @doc = doc
      end

      def cases
        @cases ||= begin
          case_rows = @doc.xpath(row_xpath)
          case_rows.map { |row| case_class.from_case_list_row(row) }
        end
      end

      def each
        cases.each { |c| yield c }
      end

      def save!
        cases.each(&:save!)
      end

      module ClassMethods
        def from_html(html)
          self.new(html)
        end
      end
    end
  end
end
