module CMA
  module CC
    module OurWork
      class Case < CMA::Case
        def case_type
          'unknown'
        end

        def self.from_link(node)
          Case.new.tap do |c|
            c.original_url = node['href']
            c.title = node.text
          end
        end
      end
    end
  end
end
