# encoding: utf-8

set_trace_func(lambda { |event, file, line, id, binding, klass|
  if event =~ /call|return/ && id.to_s == "call" && ![Proc,Method].include?(klass)
    logger.info "#{klass}#call (#{event}, #{file.split('/')[-3..-1].join('/')})"
  end
})

require File.expand_path("../../../lib/evlog", __FILE__)

class WebEvlog < Padrino::Application
  register Padrino::Rendering
  register Padrino::Mailer
  register Padrino::Helpers

  enable :sessions

  # By default the strategy uses http://www.evernote.com site.
  # wardenがあろうがなかろうがここは必須.
  use OmniAuth::Builder do
    provider :evernote, $secret.evernote.consumer_key, $secret.evernote.consumer_secret,
                        client_options: { site: 'https://sandbox.evernote.com' }
  end

  WardenOmniAuth.setup_strategies("evernote")
  use WardenOmniAuth do |config|
    # このblockはリクエストのたびに呼ばれる(全体がそうなの? useのとこだから?)
    config.redirect_after_callback = "/warden/callback"
  end

  get '/' do

    render :haml, <<-__EOL__
= flash[:notice] if flash[:notice] != nil
= link_to 'OmniAuth-sign in with evernote', '/auth/evernote'
    __EOL__
  end

  # callback route for omniauth
  get '/auth/:name/callback' do
    binding.pry
    auth = request.env["omniauth.auth"]
    case auth.provider # params[:name]
    when "evernote"
      # TODO: when existing account auth again
      EvernoteAccount.create(
        uid: auth.uid.to_s,
        sandbox: EvernoteAccount.sandbox_callback?(auth),
        encrypted_access_token: EvernoteAccount.encrypt_token(auth.credentials.token)
      )
    end
    binding.pry
    redirect '/'
  end

  get '/request_token' do
    oauth_site   = 'https://sandbox.evernote.com'
    consumer = OAuth::Consumer.new($secret.evernote.consumer_key, $secret.evernote.consumer_secret,
                        { site: oauth_site,
                          request_token_path: $secret.evernote.request_token_path,
                          authorize_path:     $secret.evernote.authorize_path,
                          access_token_path:  $secret.evernote.access_token_path })

    callback_url = "http://127.0.0.1:3000/oauth/callback"
    @request_token = consumer.get_request_token(:oauth_callback => callback_url)

    ea = EvernoteAccount.new(oauth_token: @request_token.token,
                             tmp_request_token: Base64.encode64(Marshal.dump(@request_token)))

    if ea.save
      render :haml, "= link_to 'autholize@EverNote', @request_token.authorize_url"
    else
      flash[:notice] = "failed to save EvernoteAccount"
      redirect '/'
    end

  end

  get '/oauth/callback' do
    # restore saved request_token_obj
    ea = EvernoteAccount.find(params["oauth_token"])
    request_token_obj = Marshal.load(Base64.decode64(ea.tmp_request_token))
    ea.tmp_request_token = nil && ea.save!

    access_token_obj = request_token_obj.get_access_token(oauth_verifier: params["oauth_verifier"])

    if ea.encrypt_and_save_token(access_token_obj.token)
    render :haml, <<-__EOL__
= "access_token: #{access_token_obj.token}
    __EOL__
    else
      flash[:notice] = "failed to update EvernoteAccount with access_token"
      redirect '/'
    end
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
