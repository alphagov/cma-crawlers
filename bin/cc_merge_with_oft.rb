#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'cma/cc/our_work/merge_with_oft'

CMA::CC::OurWork::MergeWithOft.new.merge!
