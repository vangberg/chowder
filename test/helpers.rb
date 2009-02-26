require 'rubygems'
require 'test/unit'
require 'context'
require 'sinatra/test'
require 'lib/chowder'

module Sinatra::Test
  def session
    env['rack.session'] || {}
  end
end

class Test::Unit::TestCase
  include Sinatra::Test
end

