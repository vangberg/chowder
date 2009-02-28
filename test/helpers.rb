require 'rubygems'
require 'test/unit'
require 'context'
require 'sinatra/test'
require 'lib/chowder'
begin
  require 'ruby-debug'
rescue LoadError; end

class Test::Unit::TestCase
  include Sinatra::Test
end

class Sinatra::Base
  include Test::Unit::Assertions
end
