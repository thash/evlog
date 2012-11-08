# encoding: utf-8
class User
  include Ripple::Document
  timestamps! # activate Ripple::Timestamps

  property :name, String
  property :email, String
  property :password, String

  one :evernote_account


  def key
    @key ||= "#{created_at.strftime("%Y%m%d%H%M%S")}/#{email.parameterize}"
  end
end

