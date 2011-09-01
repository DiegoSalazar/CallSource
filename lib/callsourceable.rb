# (c) 2011 Diego E. Salazar for USSSL
# CallSourceable: An AR plugin to keep models up to date with CallSource customer info and call details using CallSourcey XML API wrapper
require 'callsourcey'

module CallSourceable #:nodoc:
  
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    def call_sourceable
      extend  CallSourceable::SingletonMethods
      include CallSourceable::InstanceMethods
    end

  end  # END ClassMethods
  
  module SingletonMethods
    
    def get_call_source_customers
      CallSourcey
    end
    
  end # END SingletonMethods
  
  module InstanceMethods
    
    
  
  end # END InstanceMethods
  
end