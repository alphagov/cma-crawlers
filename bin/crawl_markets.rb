#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'cma/oft/markets/crawler'

CMA::OFT::Markets::Crawler.new.crawl!
