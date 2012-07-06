require 'rake'
require 'rake/tasklib'
require 'emmett'

module Emmett
  class RakeTask < ::Rake::TaskLib
    include ::Rake::DSL if defined?(::Rake::DSL)

    def configuration
      @configuration ||= build_default_configuration
    end

    # Proxy each of the configuration options.
    def name=(value);        configuration.name = value; end
    def index_page=(value);  configuration.index_page = value; end
    def section_dir=(value); configuration.section_dir = value; end
    def output_dir=(value);  configuration.output_dir = value; end
    def template=(value);    configuration.template = value; end

    attr_accessor :task_name
    attr_writer   :configuration

    def initialize(*args)
      @task_name = args.shift || :emmett
      yield self if block_given?
      desc "Generates api documentation using emmett" unless ::Rake.application.last_comment
      task task_name do
        configuration.verify!
        Emmett::DocumentManager.render! configuration
      end

    end

    private

    def build_default_configuration
      c             = Configuration.new
      c.name        = File.basename(Dir.pwd)
      c.index_page  = "api.md"
      c.section_dir = "api"
      c.output_dir  = "output"
      c.template    = :default
      c
    end

  end
end