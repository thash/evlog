# encoding: utf-8

module Ripple
  module Document
    module Finders
      module ClassMethods
        # I prefer User.all to User.list
        alias :all :list
      end
    end
  end
end

