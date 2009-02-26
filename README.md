# Chowder - Rack middleware providing session based authentication

Chowder is a Sinatra-based Rack middleware providing easy session based
authentication. You can put Chowder in front of all your other Rack based apps
to provide a single authentication mechanism for a multitude of apps. (Fix
wording, anyone?)

Chowder maps three locations:

`GET /login`
  Provides a basic login form.

`POST /login`
  Takes 'login' and 'password' params.
  Upon successful login the session key 'current_user' is set to whatever
  the block you provide the Chowder middleware with returns and the user is
  redirected to whatever path is set in the 'redirect_to' session key or  '/'
  if not set. If login fails, the user is redirected to '/login' and the
  'current_user' session key is nil or false.

`GET /logout`
  Logs out the user by setting 'current_user' session key to nil/false.

## Awesome Authentication In 3 (three) Steps
Chowder ships with a bunch of Sinatra helpers (although you can (and should)
use Chowder with all Rack based apps) to make life that lil' bit easier:

1. Create a rackup file:

    require 'chowder'
    require 'my_app'
    
    # Not optimal, but until fixed in Sinatra (see Lighthouse ticket #000)
    # Rack::Session::Cookie has to be explicitly included.
    use Rack::Session::Cookie 
    use Chowder do |login, password|
      user = User.first(:login => login , :password => password) && user.id
    end
    run Sinatra::Application

2. Make a Sinatra app that needs authentication:

    require 'sinatra'
    require 'chowder/helpers/sinatra'

    get '/' do
      'This is public'
    end

    get '/admin' do
      require_user
      'This is private'
    end

3. Start the app and discover the great taste of clam chowder.

I recommend just storing something like user ID in the session cookie and
overriding the `current_user` helper to return the user form your DB or
whatevz:

    helpers do
      def current_user
        User.first(session[:current_user])
      end
    end

## And more awesomeness is coming up:
The default login view is quite dull (and lacks <html> and <body> and whatnot),
but if you have either views/login.haml or views/login.erb, that'll be rendered
instead. Must have a form sending a POST request to /login with 'login' and 
'password' parameters.

## But wait, I'm TATFT and will not tolerate non-tested software. Where are the Chowder tests?
This was written during a train ride, and I couldn't figure out how to test
damn sessions in Sinatra. Must Fix. (OK, I drank a couple of beers and tried
again. Still can't figure.)

Oh. And this is not production-ready. Please Do Fix.

## License
MIT - see LICENSE for further information.