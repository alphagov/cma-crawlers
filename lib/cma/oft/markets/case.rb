require 'cma/oft/current/case'

module CMA
  module OFT
    module Markets
      class Case < CMA::OFT::Current::Case
        def case_type
          'markets'
        end
      end
    end
  end
end
