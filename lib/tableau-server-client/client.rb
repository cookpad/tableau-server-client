require 'uri'
require 'faraday'
require 'nokogiri'
require 'tableau-server-client/request_url'
require 'tableau-server-client/request_builder'
require 'tableau-server-client/token'
require 'tableau-server-client/paginatable_response'

module TableauServerClient

  class Client
    include RequestBuilder

    def initialize(server_url, username, password, site_name, api_version, token_lifetime, logger)
      @server_url = server_url
      @username = username
      @password = password
      @site_name = site_name
      @api_version = api_version
      @token_lifetime = token_lifetime
      @logger
    end

    attr_reader :site_name, :username, :api_version, :token_lifetime, :logger

    def server_url
      @_server_url ||= URI(@server_url.chomp("/"))
    end

    def get_collection(resource_location, &block)
      return self.to_enum(:get_collection, resource_location) unless block
      req_url = request_url(resource_location.path, resource_location.query_params)
      response = session.get req_url.to_s
      TableauServerClient::PaginatableResponse.new(self, req_url, response).each_body do |b|
        resource_location.klass.from_collection_response(self, resource_location.path, b) {|r| yield r }
      end
    end

    def get(resource_location)
      req_url = request_url(resource_location.path)
      response = session.get req_url.to_s
      resource_location.klass.from_response(self, resource_location.path, Nokogiri::XML(response.body))
    end

    def create(resource)
    end

    def delete(resource)
    end

    def update(resource)
      session.put do |req|
        req.url request_url(resource.path).to_s
        req.body = resource.to_request
      end
    end

    def session
      faraday.headers['X-Tableau-Auth'] = token.to_s
      faraday
    end

    def token
      unless @token and @token.valid?
        @token = signin
      end
      @token
    end

    private

    attr_reader :password

    def request_url(path, query_params={})
      RequestUrl.new(server_url, api_version, path, query_params)
    end

    def request_body(&block)
      build_request &block
    end

    def signin
      request = request_body {|b|
        b.credentials(name: username, password: password) {
          b.site(contentUrl: content_url)
        }
      }
      # POST without Token
      res = faraday.post do |req|
        req.url request_url("auth/signin").to_s
        req.body = request
      end
      @token = TableauServerClient::Token.parse(res.body, token_lifetime)
    end

    def content_url
      site_name == 'default' ? "" : site_name
    end

    def faraday
      @faraday ||= Faraday.new(request: {params_encoder: EmptyEncoder.new}, headers: {'Content-Type' => 'application/xml'}) do |f|
        f.response :raise_error
        #TODO Cannot set log level (always print debug log)
        #f.response :logger, logger
        f.adapter Faraday.default_adapter
      end
    end

    class EmptyEncoder
      def encode(hash)
        hash.keys.map {|k| "#{k}=#{hash[k]}" }.join('&')
      end

      def decode(str)
        str.split('&').map {|p| p.split('=') }.to_h
      end
    end

  end
end
