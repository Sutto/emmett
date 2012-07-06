require 'emmett/document'
require 'emmett/renderer'

module Emmett
  class DocumentManager

    def self.render!(*args)
      new(*args).render!
    end

    attr_reader :configuration

    def initialize(configuration)
      @configuration = configuration
    end

    def index_document
      @index_document ||= render_path(configuration.index_page, :index)
    end

    def inner_documents
      @inner_documents ||= begin
        Dir[File.join(configuration.section_dir, "**/*.md")].map do |path|
          render_path path
        end
      end
    end

    def inner_links
      @inner_links ||= inner_documents.map do |doc|
        {
          doc:      doc,
          title:    doc.title,
          short:    doc.short_name,
          link:     "./#{doc.short_name}.html",
          sections: doc.iterable_section_mapping
        }
      end.sort_by { |r| r[:title].downcase }
    end

    def render_index(renderer)
      render_document renderer, :index, index_document
    end

    def render_documents(renderer)
      inner_documents.each do |document|
        render_document renderer, :section, document
      end
    end

    def render(renderer)
      render_index renderer
      render_documents renderer
    end

    def render!
      Renderer.new(configuration).tap do |renderer|
        renderer.prepare_output
        renderer.global_context = {
          links:     inner_links,
          site_name: configuration.name
        }
        render renderer
      end
    end

    def all_urls
      out = inner_documents.inject({}) do |acc, current|
        acc[current.title] = current.http_requests.inject({}) do |ia, req|
          ia[req.section] ||= []
          ia[req.section] << req.request_line
          ia
        end
        acc
      end
    end

    private

    def render_document(renderer, template_name, document, context = {})
      renderer.render_to document.to_path_name, template_name, context.merge(content: document.highlighted_html)
    end

    def render_path(path, type = :normal)
      Document.from_path path, type
    end

  end
end