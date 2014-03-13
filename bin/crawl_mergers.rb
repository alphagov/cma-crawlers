#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'cma/oft/mergers/case_list'
require 'cma/oft/mergers/crawler'

CMA::OFT::Mergers::Crawler.new.crawl!
