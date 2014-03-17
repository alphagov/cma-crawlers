module CMA
  module MarkupHelpers
    def make_relative_links_absolute!(base_uri)
      xpath('.//a').each do |a|
        next if a['href'].nil? || a['href'] !~ %r{^/}
        a['href'] = File.join(base_uri, a['href'])
      end
    end
  end
end

Nokogiri::XML::Node.class_eval do
  include CMA::MarkupHelpers
end
