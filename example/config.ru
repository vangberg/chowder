require 'chowder'
require 'app'

use Rack::Session::Cookie
use Chowder do |login, password|
  login == "harry" && password == "clamchowder"
end
run Sinatra::Application
