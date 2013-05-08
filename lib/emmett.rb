require "emmett/version"

module Emmett

  # Autoload, so we don't auto pull in the required libraries.
  autoload :DocumentManager, 'emmett/document_manager'

  require 'emmett/railtie' if defined?(::Rails::Railtie)
end
