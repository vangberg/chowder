require 'rubygems'
require 'test/unit'
require 'context'
require 'storyteller'
require 'webrat/sinatra'
#require '/Users/h/code/webrat/lib/webrat/sinatra'
require 'rr'
require 'app'

require File.dirname(__FILE__) / 'helpers' / 'acceptance'

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
end
