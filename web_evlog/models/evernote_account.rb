# encoding: utf-8

class EvernoteAccount
  include Ripple::Document

  # Standart properties
  # property :name, String
  property :access_token, String
  property :active, Boolean, default: false

  # Relations
  # many :addresses
  # many :friends, :class_name => "Person"
  # one :account
end

