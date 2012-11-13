# -*- coding: utf-8 -*-

require "rubygems"
require "bundler/setup"
Bundler.require

$secret  = Hashie::Mash.new(YAML.load_file(File.expand_path('../../secret.yml', __FILE__)))
# $leveldb = LevelDB::DB.new("/tmp/leveldb")
$riak = Riak::Client.new
# => will be removed cuz I'll use Ripple instead

require File.expand_path("../ripple_support", __FILE__)
require File.expand_path("../warden_omniauth", __FILE__)

### Essense of EDAMTest.rb {{{
require "digest/md5"
dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.push("#{dir}/../evernote-sdk-ruby/lib")
$LOAD_PATH.push("#{dir}/../evernote-sdk-ruby/lib/thrift")
$LOAD_PATH.push("#{dir}/../evernote-sdk-ruby/lib/Evernote/EDAM")

require "thrift/types"
require "thrift/struct"
require "thrift/protocol/base_protocol"
require "thrift/protocol/binary_protocol"
require "thrift/transport/base_transport"
require "thrift/transport/http_client_transport"
require "Evernote/EDAM/user_store"
require "Evernote/EDAM/user_store_constants.rb"
require "Evernote/EDAM/note_store"
require "Evernote/EDAM/limits_constants.rb"

# }}}

