require 'cma/oft/row_based_case_list'

module CMA
  module OFT
    module Competition
      class CaseList
        include CMA::OFT::RowBasedCaseList

        def row_xpath
          '//table[1]/tr'
        end

        def case_class
          Case
        end
      end
    end
  end
end
