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
  end
end
