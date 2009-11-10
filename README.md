# Chowder - Rack middleware providing session based authentication

![Delicious!](http://cucinatestarossa.blogs.com/photos/uncategorized/hogisland_clamchowder.gif)

Chowder is a Sinatra-based Rack middleware providing easy session based
authentication. You can put Chowder in front of all your other Rack based apps
to provide a single authentication mechanism for a multitude of apps.

Chowder has two parts:

* Chowder::Basic providing 'old school' login.
* Chowder::OpenID providing .. eh, take a guess.

Both authentication mechanisms provide these URLs:

`GET /login`
  Provides a basic login form.

`GET /logout`
  Logs out the user by setting 'current_user' session key to nil/false.

Additionally *Chowder::Basic* provides

`POST /login`
  Takes 'login' and 'password' params.
  Upon successful login the session key 'current_user' is set to whatever
  the block you provide the Chowder middleware with returns and the user is
  redirected to whatever path is set in the 'redirect_to' session key or  '/'
  if not set. If login fails, the user is redirected to '/login' and the
  'current_user' session key is nil or false.

`GET /signup`
  Provides a basic signup form.
  This is only available if you have provided a :signup function to Chowder::Basic.

`POST /signup`
  Takes whatever params are on the form ('login' and 'password' by
  default) and passes them, as a hash, to your :signup callback.

And *Chowder::OpenID* provides

`POST /openid/initiate`

`GET /openid/authenticate`

## Awesome Authentication In 3 (three) Steps
Chowder ships with a bunch of Sinatra helpers (although you can (and should)
use Chowder with all Rack based apps) to make life that lil' bit easier:

### Create a rackup file:

    require 'chowder'
    require 'my_app'

    use Chowder::Basic,
      :login => lambda do |login, password|
        user = User.first(:login => login , :password => password) and user.id
      end,
      :signup => lambda do |params|
        # DataMapper style; of course you can do ActiveRecord or whatever
        u = User.create(params)
        if u.valid?
          [true, u.id]
        else
          [false, *(u.errors)]
        end
      end

    use Chowder::OpenID do |url|
      user = User.first(:openid => url) and user.id
    end
    run Sinatra::Application

### Make a Sinatra app that needs authentication:

    require 'sinatra'
    require 'sinatra/chowder'

    get '/' do
      'This is public'
    end

    get '/admin' do
      require_user
      'This is private'
    end

### Start the app and discover the great taste of clam chowder.

I recommend just storing something like user ID in the session cookie and
overriding the `current_user` helper to return the user form your DB or
whatevz:

    helpers do
      def current_user
        User.first(session[:current_user])
      end
    end

## And more awesomeness is coming up:
The default login view is quite dull, but if you have either
views/login.haml or views/login.erb, that'll be rendered instead. Must
have a form sending a POST request to /login with 'login' and
'password' parameters.

Likewise, the default signup view is overridden if you have
views/signup.haml or views/signup.erb. It needs the same 'login' and
'password' parameters as the login form. You can do whatever fancy
stuff you like; all your form params get passed right to your :signup
callback.

## License
MIT - see LICENSE for further information.
