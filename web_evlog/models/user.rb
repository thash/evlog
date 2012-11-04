# encoding: utf-8

class User
  include Ripple::Document

  # Standart properties
  # property :name, String
  property :name, String

  # Relations
  # many :addresses
  # many :friends, :class_name => "Person"
  # one :account
  one :evernote_account
end

