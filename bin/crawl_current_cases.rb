#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'cma/oft/current/crawler'

CMA::OFT::Current::Crawler.new.crawl!
