require 'openid'
require 'openid/store/filesystem'

module Chowder
  class OpenID < Base
    def host
      host = env['HTTP_HOST'] || "#{env['SERVER_NAME']}:#{env['SERVER_PORT']}"
      "http://#{host}"
    end

    def setup_consumer
      store = ::OpenID::Store::Filesystem.new('.openid')
      osession = session[:openid] ||= {}
      @consumer = ::OpenID::Consumer.new(osession, store)
    end

    post '/openid/initiate' do
      setup_consumer
      url = @consumer.begin(params['openid_identifier']).redirect_url(host, host + '/openid/authenticate')
      redirect url
    end

    get '/openid/authenticate' do
      setup_consumer
      res = @consumer.complete(request.params, host + '/openid/authenticate')
      user = @login_callback.call(res.identity_url)
      if res.is_a?(::OpenID::Consumer::SuccessResponse) && authorize(user)
        return_or_redirect_to '/'
      end
      redirect '/login'
    end
  end
end
