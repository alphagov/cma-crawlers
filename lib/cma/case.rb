require 'nokogiri'
require 'kramdown'
require 'uri'
require 'active_model'
require 'set'
require 'cma/asset'

module CMA
  class Case
    include ActiveModel::Serializers::JSON

    attr_accessor :title, :sector, :original_url, :body

    def assets
      @assets ||= Set.new
    end

    def assets=(array)
      @assets = Set.new(array.map do |v|
        Asset.new(
          v['original_url'],
          self,
          nil,
          v['content_type']
        )
      end)
    end

    def original_urls
      @original_urls ||= Set.new([original_url].compact)
    end

    def original_urls=(value)
      @original_urls = Set.new(value)
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
      super(options).tap do |hash|
        hash.delete('base_name')
        hash['case_type']  = case_type
        hash['case_state'] = case_state
        hash['original_urls'] = (original_urls << original_url).to_a
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
