#!/usr/bin/env ruby

require 'set'
require 'json'

Set.new.tap do |section_names|
  Dir['_output/our-work*.json'].each do |our_work_filename|
    json = JSON.load(File.read(File.join(Dir.pwd, our_work_filename)))
    json['markup_sections'].keys.each do |key|
      section_names << key
    end
  end

  section_names.reject {|n| %w(analysis evidence).include?(n) }.each do |name|
    puts name
  end
end

