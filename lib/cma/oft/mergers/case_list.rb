require 'cma/oft/row_based_case_list'
require 'cma/oft/mergers/case'

module CMA
  module OFT
    module Mergers
      class CaseList
        include CMA::OFT::RowBasedCaseList

        def row_xpath
          '//table/tr'
        end

        def case_class
          Case
        end
      end
    end
  end
end
