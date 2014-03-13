require 'cma/oft/row_based_case_list'
require 'cma/oft/consumer/case'

module CMA
  module OFT
    module Consumer
      class CaseList
        include CMA::OFT::RowBasedCaseList

        def row_xpath
          '//table[2]/tr'
        end

        def case_class
          Case
        end
      end
    end
  end
end
