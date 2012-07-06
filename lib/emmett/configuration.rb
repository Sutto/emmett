module Emmett
  class Configuration

    class Error < StandardError; end

    attr_accessor :name, :template, :index_page, :section_dir, :output_dir

    def verify!
      errors = []
      errors << "You must set the name attribute for emmett" if !name
      errors << "You must set the template attribute for emmett" if !template
      errors << "The index_page file must exist" unless index_page && File.exist?(index_page)
      errors << "The section_dir directory must exist" unless section_dir && File.directory?(section_dir)
      errors << "The output_dir must be set" unless output_dir
      if errors.any?
        message = "Your configuration is invalid:\n"
        errors.each { |e| message << "* #{e}\n" }
        raise Error.new(message)
      end
    end

  end
end