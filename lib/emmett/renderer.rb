require 'fileutils'
require 'handlebars'
require 'pathname'

module Emmett
  class Renderer

    attr_reader :handlebars, :global_context, :configuration, :templates
    attr_writer :global_context

    def initialize(configuration)
      @configuration  = configuration
      @templates      = configuration.to_template
      @handlebars     = Handlebars::Context.new
      @cache          = {}
      @global_context = {}
      configure_handlebars
    end

    def render(template, context = {})
      load_template(template).call global_context.merge(context)
    end

    def render_to(output, name, context = {})
      out = File.join(output_path, output)
      File.open(out, 'w+') do |f|
        f.write render(name, context)
      end
    end

    def prepare_output
      FileUtils.rm_rf   output_path
      FileUtils.mkdir_p output_path
      copy_static
    end

    private

    def output_path
      @output_path ||= configuration.output_path
    end

    def copy_static
      templates.each_static_file do |file_name, path|
        destination = File.join(output_path, file_name)
        FileUtils.mkdir_p File.dirname(destination)
        FileUtils.cp path, destination
      end
    end

    def configure_handlebars
      handlebars.partial_missing do |name|
        template = load_template "_#{name}"
        lambda do |this, context, options|
          template.call context
        end
      end
    end

    def load_template(name)
      @cache[name.to_s] ||= begin
        path = templates.template_file_path("#{name}.handlebars")
        path && handlebars.compile(File.read(path))
      end
    end

  end
end