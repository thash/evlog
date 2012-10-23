# -*- coding: utf-8 -*-

require "rubygems"
require "bundler/setup"
Bundler.require

$secret  = Hashie::Mash.new(YAML.load_file('./secret.yml'))

### Essense of EDAMTest.rb {{{
require "digest/md5"
dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.push("#{dir}/evernote-sdk-ruby/lib")
$LOAD_PATH.push("#{dir}/evernote-sdk-ruby/lib/thrift")
$LOAD_PATH.push("#{dir}/evernote-sdk-ruby/lib/Evernote/EDAM")

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

authToken = $secret.auth_token

if (authToken == "your developer token")
  puts "Please fill in your developer token"
  puts "To get a developer token, visit https://sandbox.evernote.com/api/DeveloperToken.action"
  exit(1)
end

evernoteHost = "sandbox.evernote.com"
userStoreUrl = "https://#{evernoteHost}/edam/user"

userStoreTransport = Thrift::HTTPClientTransport.new(userStoreUrl)
userStoreProtocol = Thrift::BinaryProtocol.new(userStoreTransport)
userStore = Evernote::EDAM::UserStore::UserStore::Client.new(userStoreProtocol)


versionOK = userStore.checkVersion("Evernote EDAMTest (Ruby)",
                                Evernote::EDAM::UserStore::EDAM_VERSION_MAJOR,
                                Evernote::EDAM::UserStore::EDAM_VERSION_MINOR)
puts "Is my Evernote API version up to date?  #{versionOK}"
if (!versionOK)
  exit(1)
end

noteStoreUrl = userStore.getNoteStoreUrl(authToken)

noteStoreTransport = Thrift::HTTPClientTransport.new(noteStoreUrl)
noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)

# }}}

notebooks = noteStore.listNotebooks(authToken)
blognotebook = notebooks.select{|n| n.name =~ /^blog$/i}.first

f = Evernote::EDAM::NoteStore::NoteFilter.new
f.notebookGuid = blognotebook.guid

notes = noteStore.findNotes(authToken, f, 0, 10).notes

fullnotes = notes.map{|note|
  noteStore.getNote(authToken, note.guid, true, true, false, false)
}


# ENMLまでは"あるものを入れる"ということで永続的で良い. その後の変換は改良の余地が多分にある.
# とりあえずいちばんうざいbrを改行にしただけのtextを.
# プラスしてEverNoteのデコをenmlからmarkdown(or directlly HTML)に変えられるとよい. 必要ないっちゃないけど.
def enml2markdown(enml)
  doc = Nokogiri::XML(content)
  body_div = (doc/"en-note"/"div").first
  body_div.children.map{|e| e.name == "br" ? "\n" : e.text }.join
end


db = LevelDB::DB.new("/tmp/leveldb")

fullnotes.each do |note|

  # contentHashの生成にtitleは含まれているか?
  hash = db.get "evlog/#{note.guid}/contentHash"
  next if hash == note.contentHash

  db.put "evlog/#{note.guid}/contentHash", note.contentHash
  db.put "evlog/#{note.guid}/title", note.title
  db.put "evlog/#{note.guid}/content/enml", note.content
  # ほんとは分ける. <- 何をだ
  db.put "evlog/#{note.guid}/content/markdown", enml2markdown(note.content)

end


