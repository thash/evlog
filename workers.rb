# -*- coding: utf-8 -*-
require "./lib/evlog"

class FetchNotesWorker
  @queue = :evlog_fetch_notes

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
      next if hash == Digest::SHA1.hexdigest(note.contentHash)

      $leveldb.put "evlog/#{note.guid}/contentHash", Digest::SHA1.hexdigest(note.contentHash)
      $leveldb.put "evlog/#{note.guid}/title", note.title
      # ENMLまでは"あるものを入れる"ということで永続的で良い. その後の変換(convert)は改良の余地が多分にある.
      $leveldb.put "evlog/#{note.guid}/content/enml", note.content

      Resque.enqueue(ConvertWorker, note.guid)

    end
  end

  private
  def self.setup_evernote(mode=:sandbox)
    case mode
    when :sandbox
      @authToken = $secret.sandbox_access_token
      evernoteHost = "sandbox.evernote.com"
      userStoreUrl = "https://#{evernoteHost}/edam/user"
    when :production
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

end


class ConvertWorker
  @queue = :evlog_convert_note

  # jobが入ってきたら上書きも辞さず更新
  def self.perform(guid)
    enml = $leveldb.get "evlog/#{guid}/content/enml"
    return if enml == nil
    # use return value to make HTML, if possible
    markdown = enml2markdown(enml) && html = markdown2html(markdown)
    $leveldb.put "evlog/#{guid}/content/markdown", markdown if markdown
    $leveldb.put "evlog/#{guid}/content/html", html if html
  end

  # とりあえずいちばんうざいbrを改行にしただけのtextをmarkdownとして返す.
  # プラスしてEverNoteのデコをenmlからmarkdown(or directlly HTML)に変えられるとよい. 必要ないっちゃないけど.
  def self.enml2markdown(enml)
    doc = Nokogiri::XML(enml)
    body_div = (doc/"en-note"/"div").first
    body_div.children.map{|e| e.name == "br" ? "\n" : e.text }.join
  end

  def self.markdown2html(markdown)
    return markdown #TODO
  end

end

