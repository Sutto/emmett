require 'emmett/template'
require 'json'

module Emmett
  class Configuration

    class Error < StandardError; end

    attr_accessor :name, :template, :index_page, :section_dir, :output_dir, :json_path

    def verify!
      errors = []
      if json_path && File.exist?(json_path)
        title = from_json['title']
        self.name = title if title
      else
        errors << "The json path does not exist (Given #{json_path.inspect})"
      end
      errors << "You must set the name attribute for emmett" if !name
      errors << "You must set the template attribute for emmett" if !template
      errors << "The index_page file must exist" unless index_page && File.exist?(index_page)
      errors << "The section_dir directory must exist" unless section_dir && File.directory?(section_dir)
      errors << "The output_dir must be set" unless output_dir
      errors << "The specified template does not exist" unless to_template
      if errors.any?
        message = "Your configuration is invalid:\n"
        errors.each { |e| message << "* #{e}\n" }
        raise Error.new(message)
      end
    end

    def from_json
      @json_config ||= JSON.parse(File.read(json_path))
    end

    def to_template
      @template_instance ||= Template[template]
    end

  end
end