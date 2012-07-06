require "emmett/version"

module Emmett
  require 'emmett/document_manager'
  require 'emmett/railtie' if defined?(::Rails::Railtie)
end
