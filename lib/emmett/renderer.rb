require 'fileutils'
require 'handlebars'
require 'pathname'

module Emmett
  class Renderer

    attr_reader :handlebars, :root_path, :global_context, :output_path, :template_path, :static_path
    attr_writer :global_context

    def initialize(root_path)
      @root_path      = root_path
      @template_path  = File.join root_path, 'templates'
      @output_path    = File.join root_path, 'output'
      @static_path    = File.join root_path, 'static'
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

    def copy_static
      static = Dir[File.join(static_path, "**/*")]
      static.each do |file|
        new_path = file.gsub static_path, output_path
        if File.directory? file
          FileUtils.mkdir new_path
        else
          FileUtils.cp file, new_path
        end
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
        content = File.read File.join(template_path, "#{name}.handlebars")
        handlebars.compile content
      end
    end

  end
end