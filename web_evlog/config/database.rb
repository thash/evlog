# encoding: utf-8

require 'ripple'

if File.exist?(Padrino.root + "config/riak.yml")
  Ripple.load_configuration Padrino.root.join('config', 'riak.yml'), [Padrino.env]
end
