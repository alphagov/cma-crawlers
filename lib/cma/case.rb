require 'nokogiri'
require 'kramdown'
require 'cma/case_store'
require 'uri'
require 'active_model'

module CMA
  class Case
    include ActiveModel::Serializers::JSON

    attr_accessor :title, :sector, :original_url

    attr_writer :assets

    def assets
      @assets ||= []
    end

    def base_name
      @base_name ||= CaseStore.base_name(original_url)
    end

    def save!
      CMA::CaseStore.instance.save(self)
    end

    def self.load(filename)
      CMA::CaseStore.instance.load(filename)
    end

    def case_state
      'open'
    end

    def filename
      base_name + '.json'
    end

    def attributes
      instance_values
    end

    def serializable_hash(options={})
      super.tap do |hash|
        hash.delete('base_name')
        hash['case_type']  = case_type
        hash['case_state'] = case_state
      end
    end

    def attributes=(hash)
      hash.each_pair do |k, v|
        setter = "#{k}="
        self.send(setter, v) if respond_to?(setter)
      end
    end
  end
end
