require 'singleton'
require 'json'
require 'fileutils'

module CMA
  class CaseStore
    include Singleton

    DEFAULT_LOCATION = '_output'

    attr_accessor :location

    def initialize
      self.location = DEFAULT_LOCATION
    end

    def save(_case)
      FileUtils.mkdir_p(File.join(location, _case.case_type))
      File.write(File.join(location, _case.filename), JSON.dump(_case.to_json))
    end

    def load(filename)
      json = JSON.load(File.read(filename))
      CMA::OFT::Mergers::Case.new.tap do |c|
        c.title        = json['title']
        c.original_url = json['original_url']
        c.sector       = json['sector']
      end
    end

    def find(url)
      load(File.join(location, CaseStore.base_name(url) + '.json'))
    end

    def self.base_name(original_url)
      original_url = URI.parse(original_url) unless original_url.is_a?(URI)
      original_url.path[1..-1].gsub('/', '-')
    end

    def clean!
      Dir["#{location}/*"].each {|entry| FileUtils.rmtree(entry)}
    end
  end
end
