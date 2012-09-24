require 'pygments'
require 'github/markdown'
require 'github/markup'
require 'nokogiri'

require 'emmett/http_request_processor'

module Emmett

  def self.normalize_name(text)
    text.strip.downcase.gsub(/\W+/, '-').gsub(/-+/, '-').gsub(/(^-|-$)/, '')
  end

  class Section < Struct.new(:name)

    def groups
      @groups ||= []
    end

    def groups=(value)
      @groups = Array value
    end

    def singular?
      @groups.one?
    end

    def ==(other)
      other.is_a?(self.class) && other.name == name
    end

    def to_hash
      {
        :name     => name,
        :singular => singular?,
        :groups   => groups.map(&:to_hash)
      }.tap do |result|
        if singular?
          group = groups.first.to_hash
          result[:endpoints] = group[:endpoints]
          result[:url]       = group[:url]
        end
      end
    end

  end

  class Group < Struct.new(:name)

    attr_reader :slug, :document

    def ==(other)
      other.is_a?(self.class) && other.name == name
    end

    def initialize(name, document)
      @slug = Emmett.normalize_name name
      @document = document
      super name
    end

    def to_hash
      {
        :name => name,
        :slug => slug,
        :endpoints => endpoints.map(&:to_hash),
        :url       => document.to_path_name
      }
    end

    def endpoints
      @endpoints ||= []
    end

    def endpoints=(value)
      @endpoints = Array value
    end

  end

  class Endpoint < Struct.new(:name)

    def ==(other)
      other.is_a?(self.class) && other.name == name
    end

    attr_reader :slug, :document

    def initialize(name, document)
      @slug = Emmett.normalize_name name
      @document = document
      super name
    end

    def to_hash
      {
        :name => name,
        :slug => slug,
        :url  => "#{document.to_path_name}##{slug}"
      }
    end

  end

  class Document < Struct.new(:file_name, :content, :type)

    def self.from_path(path, type = :normal)
      Document.new path, GitHub::Markup.render(path, File.read(path)), type
    end

    def group_names
      @group_name ||= document.css('h1').map(&:text)
    end

    def endpoint_names
      @endpoint_names ||= document.css('h2').map(&:text)
    end

    def groups
      @groups ||= group_names.map do |name|
        group = Group.new(name, self)
        group.endpoints = endpoints
        group
      end
    end

    def endpoints
      @endpoints ||= endpoint_names.map { |name| Endpoint.new(name, self) }
    end

    def short_name
      @short_name ||= begin
        if type == :index
          "index"
        else
          File.basename(file_name).split(".")[0..-2].join(".")
        end
      end
    end

    def document
      @document ||= Nokogiri::HTML(content)
    end

    def title
      @title ||= group_names.first
    end

    def highlighted_html
      @highlighted_html ||= begin
        doc = document.clone
        doc.css('pre[lang]').each do |block|
          inner                = block.at_css('code')
          highlighted          = Pygments.highlight(inner.inner_html, options: {encoding: 'utf-8'}, lexer: block[:lang])
          highlighted_fragment = Nokogiri::HTML::DocumentFragment.parse highlighted
          highlighted_fragment["data-code-lang"] = block[:lang]
          block.replace highlighted_fragment
        end

        mapping = endpoints.inject({}) { |acc, e| acc[e.name] = e.slug; acc }
        doc.css('h2').each do |header|
          if (identifier = mapping[header.text])
            header[:id] = identifier
          end
        end

        unless short_name == 'index'
          # Now, insert an endpoints content before the start of it.
          toc = Nokogiri::HTML::DocumentFragment.parse toc_html
          doc.at_css('h2').add_previous_sibling toc
        end

        doc.css('body').inner_html
      end
    end

    def toc_html
      [].tap do |html|
        html << "<h2>Endpoints</h2>"
        html << "<ul id='endpoints'>"

        endpoints.each do |endpoint|
          html << "<li><a href='##{endpoint.slug}'>#{endpoint.name}</a></li>"
        end
        html << "</ul>"
      end.join("")
    end

    def to_path_name
      "#{short_name}.html"
    end

    def code_blocks
      @code_blocks ||= begin
        last_header = nil
        blocks      = []
        document.css('h2, pre[lang]').each do |d|
          if d.name == 'h2'
            last_header = d.text
          else
            blocks << [d[:lang], d.at_css('code').text, last_header]
          end
        end
        blocks
      end
    end

    # Extra / process HTTP blocks to get extra information.

    def http_blocks
      @http_blocks ||= code_blocks.select { |r| r.first == "http" }.map { |r| r[1..-1] }
    end

    def http_requests
      @http_requests ||= http_blocks.select do |cb|
        first_line = cb[0].lines.first.strip
        first_line =~ /\A[A-Z]+ (\S+) HTTP\/1\.1\Z/
      end.map { |r| HTTPRequestProcessor.new(*r) }
    end

    def http_responses
      @http_responses ||= http_blocks.select do |cb|
        first_line = cb.lines.first.strip
        first_line =~ /\AHTTP\/1\.1 (\d+) (\w+)\Z/
      end
    end

  end
end