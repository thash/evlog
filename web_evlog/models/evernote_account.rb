# encoding: utf-8

class EvernoteAccount
  include Ripple::Document
  timestamps! # activate Ripple::Timestamps

  property :oauth_token, String
  property :tmp_request_token, String
  property :encrypted_access_token, String
  property :active, Boolean, default: false

  def key
    @key ||= "#{oauth_token}"
  end


  # We need to sign the message in order to avoid padding attacks.
  # ref: http://www.limited-entropy.com/padding-oracle-attacks
  def encrypt_and_save_token(token)
    encryptor = ActiveSupport::MessageEncryptor.new($secret.salt)
    self.encrypted_access_token = encryptor.encrypt_and_sign(token)
    self.save
  end

  # cuz we don't have raw access_token in DB, instead decrypt each time.
  def access_token
    encryptor = ActiveSupport::MessageEncryptor.new($secret.salt)
    encryptor.decrypt_and_verify(self.encrypted_access_token)
  end

end

