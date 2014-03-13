require 'singleton'
require 'json'
require 'fileutils'

require 'cma/oft/mergers/case'
require 'cma/oft/competition/case'
require 'cma/oft/consumer/case'

module CMA
  class CaseStore
    include Singleton

    DEFAULT_LOCATION = '_output'

    MERGER_CASE      = /OFTwork-mergers-Mergers/
    COMPETITION_CASE = /OFTwork-oft-current-cases-competition/
    CONSUMER_CASE    = /OFTwork-oft-current-cases-consumer/

    attr_accessor :location

    def initialize
      self.location = DEFAULT_LOCATION
    end

    def save(_case)
      FileUtils.mkdir_p(location)
      File.write(
        File.join(location, _case.filename),
        JSON.pretty_generate(JSON.parse(_case.to_json))
      )
    end

    def load_class(filename)
      case filename
        when MERGER_CASE      then CMA::OFT::Mergers::Case
        when COMPETITION_CASE then CMA::OFT::Competition::Case
        when CONSUMER_CASE    then CMA::OFT::Consumer::Case
        else
          raise ArgumentError, "Class for #{filename} not found"
      end
    end

    def load(filename)
      load_class(filename).new.tap do |c|
        c.from_json(File.read(filename))
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
