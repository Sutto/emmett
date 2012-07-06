require 'pygments'
require 'github/markdown'
require 'github/markup'
require 'nokogiri'

require 'emmett/http_request_processor'

module Emmett
  class Document < Struct.new(:file_name, :content)

    def self.from_path(path)
      puts "Rendering #{path} - #{File.read(path)}"
      Document.new path, GitHub::Markup.render(path, File.read(path))
    end

    def short_name
      @short_name ||= begin
        short_name = File.basename(file_name).split(".")[0..-2].join(".")
        short_name == "api" ? "index" : short_name
      end
    end

    def document
      @document ||= Nokogiri::HTML(content)
    end

    def sections
      @sections ||= document.css('h2').map(&:text)
    end

    def section_mapping
      @section_mapping ||= sections.inject({}) do |acc, current|
        acc[current] = current.strip.downcase.gsub(/\W+/, '-').gsub(/-+/, '-').gsub(/(^-|-$)/, '')
        acc
      end
    end

    def title
      @title ||= document.at_css('h1').text
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

        mapping = section_mapping
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

        section_mapping.each_pair do |section, slug|
          html << "<li><a href='##{slug}'>#{section}</a></li>"
        end
        html << "</ul>"
      end.join("")
    end

    def iterable_section_mapping
      section_mapping.map { |(n,v)| {name: n, hash: v} }
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