# encoding: utf-8

class EvernoteAccount
  include Ripple::Document
  timestamps! # activate Ripple::Timestamps

  property :uid                    , String
  property :sandbox                , Boolean , default: true
  property :encrypted_access_token , String
  property :active                 , Boolean , default: false


  def self.sandbox_callback?(auth)
    site = auth.extra.access_token.consumer.options[:site]
    site.index("sandbox").nil? ? false : true
  end

  # We need to sign the message in order to avoid padding attacks.
  # ref: http://www.limited-entropy.com/padding-oracle-attacks
  def self.encrypt_token(token)
    encryptor = ActiveSupport::MessageEncryptor.new($secret.salt)
    encryptor.encrypt_and_sign(token)
  end


  def key
    @key ||= "#{(sandbox ? "sandbox" : "evernote")}-#{uid}"
  end

  # cuz we don't have raw access_token in DB, instead decrypt each time.
  def access_token
    encryptor = ActiveSupport::MessageEncryptor.new($secret.salt)
    encryptor.decrypt_and_verify(self.encrypted_access_token)
  end

end

