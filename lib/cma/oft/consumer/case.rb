require 'cma/oft/current/case'

module CMA
  module OFT
    module Consumer
      class Case < CMA::OFT::Current::Case
        def case_type
          'consumer-enforcement'
        end
      end
    end
  end
end
