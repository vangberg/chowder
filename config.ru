$:.unshift('lib')
Dir['lib/*'].each do |lib|
  $:.unshift(File.join(File.dirname(__FILE__), lib))
end
require 'chowder'
require 'app'

use Rack::Session::Cookie
use Chowder do |login, password|
  login == "harry" && password == "clamchowder"
end
run Sinatra::Application
