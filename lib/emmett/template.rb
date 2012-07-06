module Emmett
  class Template
    class Error < StandardError; end

    REQUIRED_TEMPLATES = %w(index section)

    class << self

      def registry
        @registry ||= {}
      end

      def register(name, value)
        registry[name.to_sym] = value
      end

      def [](name)
        registry.fetch(name.to_sym) { raise "Emmett does not know a template by the name '#{name}'" }
      end

      def add(name, path)
        new(name, path).tap do |template|
          template.verify!
          template.register
        end
      end

    end

    attr_reader :name, :root

    def initialize(name, root)
      @name = name && name.to_sym
      @root = root.to_s
    end

    def template_format; ".handlebars"; end

    def verify!
      errors = []
      errors << "Ensure the root directory exists" unless File.directory?(root)
      errors << "Ensure the name is set" unless name
      errors << "Ensure the template has a templates subdirectory" unless File.directory?(template_path)
      errors << "Ensure the template static path is a directory if present" if File.exist?(static_path) && !File.directory?(static_path)
      errors << "Missing the following files in your template: #{missing_templates.join(", ")}" if missing_templates.any?
      if errors.any?
        message = "The following errors occured trying to add your template:\n"
        errors.each { |e| message << "* #{message}\n" }
        raise Error.new(mesage)
      end
    end

    def missing_templates
      @missing_templates ||= REQUIRED_TEMPLATES.select do |template|
        template_file_path(template).nil?
      end
    end

    def static_path
      @static_path ||= File.join(root, 'static')
    end

    def template_path
      @template_path ||= File.join(root, 'templates')
    end

    def template_file_path(name)
      path = File.join(template_path, "#{name}.#{template_format}")
      File.exist?(path) ? path : nil
    end

    def has_template?(name)
      File.exist?
    end

    def each_static_file
      Dir[File.join(static_path, '**/*')].select { |f| File.file?(f) }.each do |file|
        relative_name = file.gsub(static_path, "")
        yield relative_name, file
      end
    end

    def register
      self.class.register name, self
    end

    # Add the default template, located within the gem.
    add :default, File.expand_path('../../../templates/default', __FILE__)

  end
end