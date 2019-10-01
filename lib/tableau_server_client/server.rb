require 'tableau_server_client/client'
require 'tableau_server_client/resources/site'
require 'tableau_server_client/resources/schedule'
require 'tableau_server_client/exception'
require 'logger'

module TableauServerClient
  class Server

    def initialize(server_url, username, password,
                   site_name: "default", api_version: "3.1", token_lifetime: 240,
                   log_level: :info, impersonation_username: nil)
      @server_url = server_url
      @username = username
      @password = password
      @site_name = site_name
      @api_version = api_version
      @token_lifetime = token_lifetime
      @logger = ::Logger.new(STDOUT)
      @logger.level = ::Logger.const_get(log_level.upcase.to_sym)
      @impersonation_username = impersonation_username
    end

    attr_reader :server_url, :username, :site_name, :api_version, :token_lifetime, :logger, :impersonation_username

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

    def client
      @client ||= Client.new(server_url, username, password, site_name, api_version, token_lifetime, @logger, user_id(impersonation_username))
    end

    private

    attr_reader :password

    def user_id(username)
      return nil unless username
      admin_client.get_collection(Resources::Site.location(path)).each do |site|
        user = site.users(filter: ["name:eq:#{username}"]).first
        if user
          return user.id
        end
      end
      raise TableauServerClientError.new("User '#{username}' not found.")
    end

    def admin_client
      @admin_client ||= Client.new(server_url, username, password, site_name, api_version, token_lifetime, @logger, nil)
    end

  end
end
