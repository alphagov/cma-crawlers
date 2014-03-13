#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'cma/cc/our_work/crawler'

CMA::CC::OurWork::Crawler.new.crawl!
