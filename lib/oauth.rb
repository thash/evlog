# -*- coding: utf-8 -*-

require File.expand_path("../evlog", __FILE__)

@callback_url = "http://127.0.0.1:3000/"
@oauth_site   = 'https://sandbox.evernote.com'

@consumer = OAuth::Consumer.new($secret.evernote.consumer_key, $secret.evernote.consumer_secret,
                                { site: @oauth_site,
                                  request_token_path: $secret.evernote.request_token_path,
                                  authorize_path:     $secret.evernote.authorize_path,
                                  access_token_path:  $secret.evernote.access_token_path })

@request_token = @consumer.get_request_token(:oauth_callback => @callback_url)

# redirect_to @request_token.authorize_url
# get callback and oauth_verifier
# oauth_verifier = params[:oauth_verifier]
# access_token_obj = @request_token.get_access_token(oauth_verifier: oauth_verifier)
# @access_token = access_token_obj.token

