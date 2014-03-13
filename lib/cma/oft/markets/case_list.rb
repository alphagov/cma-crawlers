require 'cma/oft/row_based_case_list'
require 'cma/oft/markets/case'

module CMA
  module OFT
    module Markets
      class CaseList
        include CMA::OFT::RowBasedCaseList

        def row_xpath
          '//table[3]/tr'
        end

        def case_class
          Case
        end
      end
    end
  end
end
