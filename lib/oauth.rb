# -*- coding: utf-8 -*-

require "./evlog"

@consumer = OAuth::Consumer.new($secret.consumer_key, $secret.consumer_secret,
                                { site: 'https://sandbox.evernote.com/oauth'
                                  })

