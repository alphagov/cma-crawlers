require 'cma/case_store'
require 'fileutils'
require 'active_model'

module CMA
  class Asset
    include ActiveModel::Serializers::JSON

    attr_accessor :original_url, :content, :content_type, :owner

    def initialize(original_url, owner, content, content_type)
      self.original_url = original_url
      self.owner        = owner
      self.content      = content
      self.content_type = content_type
    end

    def serializable_hash(options = {})
      %w(original_url content_type filename).inject({}) do |hash, key|
        hash[key] = self.send(key.to_sym)
        hash
      end.tap do |hash|
        hash['filename'] = File.join(owner.base_name, filename) if owner
      end
    end

    def attributes
      instance_values
    end

    def filename
      uri = original_url.is_a?(URI) ? original_url : URI.parse(original_url)
      @filename ||= File.basename(uri.path)
    end

    def save!
      asset_dir = File.join(CMA::CaseStore.instance.location, owner.base_name)
      FileUtils.mkdir_p(asset_dir)
      File.write("#{asset_dir}/#{filename}", content)
    end

    def ==(other)
      eql?(other)
    end

    def eql?(other)
      hash == other.hash
    end

    def hash
      original_url.hash
    end
  end
end
