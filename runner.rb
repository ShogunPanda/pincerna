#!/usr/bin/env ruby
# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "rubygems"
require File.dirname(__FILE__) + "/lib/pincerna"

puts Pincerna::Base.execute!(ARGV.shift.to_sym, ARGV.join(" ")) if !ARGV.empty?