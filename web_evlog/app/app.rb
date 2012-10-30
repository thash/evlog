require File.expand_path("../../../lib/evlog", __FILE__)

class WebEvlog < Padrino::Application
  register Padrino::Rendering
  register Padrino::Mailer
  register Padrino::Helpers

  enable :sessions

  get '/' do
    render :haml, "= link_to 'login', '/request_token'"
  end


  get '/request_token' do
    @request_token = make_request_token
    render :haml, "= link_to 'autholize@EverNote', @request_token.authorize_url"
  end

  get '/oauth/callback' do
    oauth_verifier   = params["oauth_verifier"] # これが大事
    request_token    = #TODO
    # verifyしたrequest_tokenを使い回さないといけないが,
    # Padrino(Sinatra)がリクエストごとにリロードするので(?)sessionが保持されない
    access_token_obj = request_token.get_access_token(oauth_verifier: oauth_verifier)
    @access_token    = access_token_obj.token # save token

    render :haml, <<-__EOL__
= "oauth_verifier: #{oauth_verifier}"
= "request_token: #{request_token}"
= "access_token: #{@access_token}"
    __EOL__
  end


  def make_consumer
    oauth_site   = 'https://sandbox.evernote.com'
    OAuth::Consumer.new($secret.evernote.consumer_key, $secret.evernote.consumer_secret,
                        { site: oauth_site,
                          request_token_path: $secret.evernote.request_token_path,
                          authorize_path:     $secret.evernote.authorize_path,
                          access_token_path:  $secret.evernote.access_token_path })

  end

  def make_request_token
    callback_url = "http://127.0.0.1:3000/oauth/callback"
    make_consumer.get_request_token(:oauth_callback => callback_url)
  end


  ##
  # Caching support
  #
  # register Padrino::Cache
  # enable :caching
  #
  # You can customize caching store engines:
  #
  #   set :cache, Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1))
  #   set :cache, Padrino::Cache::Store::Memcache.new(::Dalli::Client.new('127.0.0.1:11211', :exception_retry_limit => 1))
  #   set :cache, Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0))
  #   set :cache, Padrino::Cache::Store::Memory.new(50)
  #   set :cache, Padrino::Cache::Store::File.new(Padrino.root('tmp', app_name.to_s, 'cache')) # default choice
  #

  ##
  # Application configuration options
  #
  # set :raise_errors, true       # Raise exceptions (will stop application) (default for test)
  # set :dump_errors, true        # Exception backtraces are written to STDERR (default for production/development)
  # set :show_exceptions, true    # Shows a stack trace in browser (default for development)
  # set :logging, true            # Logging in STDOUT for development and file for production (default only for development)
  # set :public_folder, "foo/bar" # Location for static assets (default root/public)
  # set :reload, false            # Reload application files (default in development)
  # set :default_builder, "foo"   # Set a custom form builder (default 'StandardFormBuilder')
  # set :locale_path, "bar"       # Set path for I18n translations (default your_app/locales)
  # disable :sessions             # Disabled sessions by default (enable if needed)
  # disable :flash                # Disables sinatra-flash (enabled by default if Sinatra::Flash is defined)
  # layout  :my_layout            # Layout can be in views/layouts/foo.ext or views/foo.ext (default :application)
  #

  ##
  # You can configure for a specified environment like:
  #
  #   configure :development do
  #     set :foo, :bar
  #     disable :asset_stamp # no asset timestamping for dev
  #   end
  #

  ##
  # You can manage errors like:
  #
  #   error 404 do
  #     render 'errors/404'
  #   end
  #
  #   error 505 do
  #     render 'errors/505'
  #   end
  #
end
