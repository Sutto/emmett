require 'emmett/document'
require 'emmett/renderer'
require 'set'

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

    def indexed_documents
      @indexed_documents ||= inner_documents.inject({}) do |acc, document|
        acc[document.short_name] = document
        acc
      end
    end

    def sections
      @sections ||= Hash.new.tap { |s| process_sections s }.values
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
      process_sections
      render_index renderer
      render_documents renderer
    end

    def render!
      Renderer.new(configuration).tap do |renderer|
        renderer.prepare_output
        all_groups = sections.map(&:groups).flatten.sort_by(&:name).uniq
        renderer.global_context = {
          sections:  sections.map(&:to_hash),
          groups:    all_groups.map(&:to_hash),
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

    def process_sections(into = {})
      configuration_sections = Array(configuration.from_json['sections'])
      seen                   = Set.new
      configuration_sections.each do |s|
        name           = s['name']
        section        = (into[name] ||= Section.new(name))
        entries        = Array(s['children']).map { |n| indexed_documents[n] }.compact.map(&:groups).flatten.uniq
        section.groups += entries
        seen           += entries
      end
      missing = (inner_documents.map(&:groups).flatten.uniq - seen.to_a)
      missing.each do |group|
        # This document doesn't have a section, so we need to specify it.
        section         = (into[group.name] ||= Section.new(group.name))
        section.groups << group
      end
      into
    end

    def render_document(renderer, template_name, document, context = {})
      renderer.render_to document.to_path_name, template_name, context.merge(content: document.highlighted_html)
    end

    def render_path(path, type = :normal)
      Document.from_path path, type
    end

  end
end