require 'spec_helper'

describe "EvernoteAccount Model" do
  let(:evernote_account) { EvernoteAccount.new }
  it 'can be created' do
    evernote_account.should_not be_nil
  end
end
