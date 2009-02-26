$:.unshift(File.join(File.dirname(File.expand_path(__FILE__)), '..', 'lib'))
$:.unshift(File.dirname(File.expand_path(__FILE__)))
require 'chowder'
require 'app'

use Rack::Session::Cookie
use Chowder::Basic do|login, password|
  login == "harry" && password == "clamchowder"
end
use Chowder::OpenID do |url|
  url == 'http://harry.vangberg.name/' ? url : nil
end
run Sinatra::Application
