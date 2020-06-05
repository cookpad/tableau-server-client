require 'uri'
require 'faraday'
require 'nokogiri'
require 'tableau_server_client/request_url'
require 'tableau_server_client/request_builder'
require 'tableau_server_client/token'
require 'tableau_server_client/paginatable_response'
require 'tempfile'
require 'zip'
require 'stringio'

module TableauServerClient

  class Client
    include RequestBuilder

    def initialize(server_url, username, password, content_url, api_version, token_lifetime, logger, impersonation_user_id)
      @server_url = server_url
      @username = username
      @password = password
      @content_url = content_url
      @api_version = api_version
      @token_lifetime = token_lifetime
      @logger = logger
      @impersonation_user_id = impersonation_user_id
    end

    attr_reader :content_url, :username, :api_version, :token_lifetime, :logger, :impersonation_user_id

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
      xml =  Nokogiri::XML(response.body).xpath("//xmlns:tsResponse").children.first
      resource_location.klass.from_response(self, resource_location.path, xml)
    end

    def create(resource, path: nil, request: nil)
      path = path || resource.path
      request = request || resource.to_request
      response = session.post do |req|
        req.url request_url(path).to_s
        req.body = request
      end
      Nokogiri::XML(response.body).xpath("//xmlns:tsResponse").children.first
    end

    def download(resource_location, file_path: nil)
      req_url = request_url("#{resource_location.path}/content", resource_location.query_params)
      response = session.get req_url.to_s
      if file_path
        File.write(file_path, response.body)
      end
      return response
    end

    def download_image(resource_location, file_path: nil)
      req_url = request_url("#{resource_location.path}/image", resource_location.query_params)
      response = session.get req_url.to_s
      if file_path
        File.write(file_path, response.body)
      end
      return response.body
    end

    def update(resource, path: nil, request: nil)
      path = path || resource.path
      request = request || resource.to_request
      session.put do |req|
        req.url request_url(path).to_s
        req.body = request
      end
    end

    def delete(resource, path: nil)
      path = path || resource.path
      session.delete request_url(path).to_s
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
          b.user(id: impersonation_user_id) if impersonation_user_id
        }
      }
      # POST without Token
      res = faraday.post do |req|
        req.url request_url("auth/signin").to_s
        req.body = request
      end
      @token = TableauServerClient::Token.parse(res.body, token_lifetime)
    end

    def faraday
      @faraday ||= Faraday.new(request: {params_encoder: EmptyEncoder.new}, headers: {'Content-Type' => 'application/xml'}) do |f|
        f.response :raise_error
        f.response :logger, logger
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
