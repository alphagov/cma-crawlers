#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'cma/cc/body_generator'

CMA::CC::BodyGenerator.new.generate!
