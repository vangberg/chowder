require 'rubygems'
require 'test/unit'
require 'rack/test'
require 'lib/chowder'
begin
  require 'ruby-debug'
rescue LoadError; end

class Test::Unit::TestCase
  include Rack::Test::Methods
end

class Sinatra::Base
  include Test::Unit::Assertions
end
