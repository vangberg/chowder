require 'sinatra'
require 'chowder/helpers/sinatra'

get '/' do
  'Welcome to the Impirial Intranet(tm)<br />
  <a href="/admin/">Look at teh diamonds!</a>'
end

get '/admin/*' do
  require_user
  pass
end

get '/admin/' do
  "Can haz gold 'n diamonds!<br />
  <a href='/logout'>Log out!</a> "
end

get '/admin/edit' do
  "Woah"
end
