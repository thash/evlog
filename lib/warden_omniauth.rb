# -*- coding: utf-8 -*-

### 単体で使う
#class WardenOmniAuth::Strategy
#  def authenticate!
#    binding.pry
#    session = env[SESSION_KEY]
#    session[SCOPE_KEY] = scope
#
#    # set the user if one exists
#    # otherwise, redirect for authentication
#    if user = (env['omniauth.auth'] || env['rack.auth'] || request['auth']) # TODO: Fix..  Completely insecure... do not use this will look in params for the auth.  Apparently fixed in the new gem
#    # if user = (env['rack.auth'] || request['auth']) # TODO: Fix..  Completely insecure... do not use this will look in params for the auth.  Apparently fixed in the new gem
#
#      success! self.class.on_callback[user]
#    else
#      path_prefix = OmniAuth::Configuration.instance.path_prefix
#      redirect! File.join(path_prefix, self.class.omni_name)
#    end
#  end
#end
