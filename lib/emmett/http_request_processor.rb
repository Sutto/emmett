require 'http/parser'
require 'oj'

module Emmett
  class HTTPRequestProcessor

    attr_reader :headers, :body, :method, :url, :http_version, :section

    def initialize(request, section)
      @raw_request = request.gsub(/\r?\n/m, "\r\n")
      @body        = ""
      @section     = section
      parse!
    end

    def parse!
      parser = Http::Parser.new

      parser.on_headers_complete = proc do
        @http_version = parser.http_version
        @method       = parser.http_method
        @url          = parser.request_url
        @headers      = parser.headers
      end

      parser.on_body = proc do |chunk|
        # One chunk of the body
        @body << chunk
      end

      parser.on_message_complete = proc do |env|
        @parsed = true
      end

      @parsed = false
      parser << @raw_request
      parser << "\r\n" until @parsed
    end

    def has_body?
      @body.strip.length > 0
    end

    def authenticated?
      headers['Authorization'] && headers['Authorization'] =~ /bearer/i
    end

    def request_line
      "#{method} #{url}"
    end

    def json?
      headers['Content-Type'] && headers['Content-Type'].include?("application/json")
    end

    def has_valid_json?
      return @has_valid_json if instance_variable_defined?(:@has_valid_json)

      begin
        Oj.load body
        @has_valid_json = true
      rescue SyntaxError
        @has_valid_json = false
      end

      @has_valid_json
    end

  end
end