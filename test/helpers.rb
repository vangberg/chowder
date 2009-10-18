require 'rubygems'
require 'test/unit'
require 'sinatra/test'
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))
require 'chowder'
begin
  require 'ruby-debug'
rescue LoadError; end

class Test::Unit::TestCase
  include Sinatra::Test
end

class Sinatra::Base
  include Test::Unit::Assertions
end
