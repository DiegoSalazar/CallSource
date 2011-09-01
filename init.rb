require 'callsourceable'
#Dir.glob(File.dirname(__FILE__) + '/lib/extra_space_models/*.rb').map { |lib| require lib }
ActiveRecord::Base.send(:include, CallSourceable)
