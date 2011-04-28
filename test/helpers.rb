$LOAD_PATH.unshift("lib")

require 'rubygems'
require 'test/unit'
require 'rack/test'
require 'chowder'

begin
  require 'ruby-debug'
rescue LoadError; end

class Test::Unit::TestCase
  include Rack::Test::Methods
end

class Sinatra::Base
  include Test::Unit::Assertions
end
