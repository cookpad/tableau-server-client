require 'uri'

module TableauServerClient
  class RequestUrl
    def initialize(url, api_version, path, params)
      @url = url
      @api_version = api_version
      @path = path
      @params = params
    end

    attr_reader :url, :api_version
    attr_accessor :path, :params

    def merge_params!(params)
      @params.merge!(params)
      self
    end

    def to_s
      URI("#{url}/api/#{api_version}/#{path}?#{query_params}").to_s
    end

    def query_params
      return "" if params.empty?
      params.keys.map {|k| URI.encode_www_form({k => params[k]}) }.join("&")
    end
  end
end
