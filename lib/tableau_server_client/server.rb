require 'tableau_server_client/client'
require 'tableau_server_client/resources/site'
require 'tableau_server_client/resources/schedule'
require 'logger'

module TableauServerClient
  class Server

    def initialize(server_url, username, password,
                   site_name: "default", api_version: "3.1", token_lifetime: 240,
                   log_level: :info)
      @logger = ::Logger.new(STDOUT)
      @logger.level = ::Logger.const_get(log_level.upcase.to_sym)
      @client = Client.new(server_url, username, password, site_name, api_version, token_lifetime, @logger)
    end

    def sites
      client.get_collection Resources::Site.location(path)
    end

    def site(id)
      client.get Resources::Site.location(path, id)
    end

    def schedules
      client.get_collection Resources::Schedule.location(path)
    end

    def path
      nil
    end

    private

    attr_reader :client

  end
end
