# -*- coding: utf-8 -*-
require "./evlog"

class FetchNoteWorker
  @queue = :fetch_note

  def self.perform(notebookname="Blog")
    setup_evernote

    notebooks = @noteStore.listNotebooks(@authToken)
    blognotebook = notebooks.select{|n| n.name == notebookname}.first
    # raise if blognotebook not found

    f = Evernote::EDAM::NoteStore::NoteFilter.new
    f.notebookGuid = blognotebook.guid

    notes = @noteStore.findNotes(@authToken, f, 0, 10).notes

    fullnotes = notes.map{|note|
      @noteStore.getNote(@authToken, note.guid, true, true, false, false)
    }

    fullnotes.each do |note|

      # contentHashの生成にtitleは含まれているか?
      hash = $leveldb.get "evlog/#{note.guid}/contentHash"
      next if hash == note.contentHash

      $leveldb.put "evlog/#{note.guid}/contentHash", note.contentHash
      $leveldb.put "evlog/#{note.guid}/title", note.title
      $leveldb.put "evlog/#{note.guid}/content/enml", note.content
      $leveldb.put "evlog/#{note.guid}/content/markdown", enml2markdown(note.content)

    end
  end

  private
  def self.setup_evernote(mode=:sandbox)
    case mode
    when :sandbox
      @authToken = $secret.auth_token
      evernoteHost = "sandbox.evernote.com"
      userStoreUrl = "https://#{evernoteHost}/edam/user"
    end

    userStoreTransport = Thrift::HTTPClientTransport.new(userStoreUrl)
    userStoreProtocol = Thrift::BinaryProtocol.new(userStoreTransport)
    userStore = Evernote::EDAM::UserStore::UserStore::Client.new(userStoreProtocol)


    versionOK = userStore.checkVersion("Evernote EDAMTest (Ruby)",
                                        Evernote::EDAM::UserStore::EDAM_VERSION_MAJOR,
                                        Evernote::EDAM::UserStore::EDAM_VERSION_MINOR)
    exit(1) if (!versionOK)

    noteStoreUrl = userStore.getNoteStoreUrl(@authToken)

    noteStoreTransport = Thrift::HTTPClientTransport.new(noteStoreUrl)
    noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
    @noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)
  end

  # ENMLまでは"あるものを入れる"ということで永続的で良い. その後の変換は改良の余地が多分にある.
  # とりあえずいちばんうざいbrを改行にしただけのtextを.
  # プラスしてEverNoteのデコをenmlからmarkdown(or directlly HTML)に変えられるとよい. 必要ないっちゃないけど.
  def self.enml2markdown(enml)
    doc = Nokogiri::XML(content)
    body_div = (doc/"en-note"/"div").first
    body_div.children.map{|e| e.name == "br" ? "\n" : e.text }.join
  end

end

