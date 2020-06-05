require 'tableau_server_client/client'
require 'tableau_server_client/resources/site'
require 'tableau_server_client/resources/schedule'
require 'tableau_server_client/exception'
require 'logger'

module TableauServerClient
  class Server

    #Implement for_token
    #def for_token(token)

    def initialize(server_url, username, password,
                   content_url: "", api_version: "3.1", token_lifetime: 240,
                   log_level: :info, impersonation_username: nil)
      @server_url = server_url
      @username = username
      @password = password
      @content_url = content_url
      @api_version = api_version
      @token_lifetime = token_lifetime
      @logger = ::Logger.new(STDOUT)
      @logger.level = ::Logger.const_get(log_level.upcase.to_sym)
      @impersonation_username = impersonation_username
    end

    attr_reader :server_url, :username, :content_url, :api_version, :token_lifetime, :logger, :impersonation_username

    def sites
      client.get_collection(Resources::Site.location(path)).map {|s|
        client_for_site(s.content_url).get_collection(Resources::Site.location(path)).select {|x| x.id == s.id }.first
      }
    end

    def site(id)
      sites.select { |s| s.id == id }.first
    end

    def site_by_name(site_name)
      sites.select { |s| s.name == site_name }.first
    end

    def full_site(id)
      client_for_site(client.get(Resources::Site.location(path, id)).content_url).get Resources::Site.location(path, id)
    end

    def schedules
      client.get_collection Resources::Schedule.location(path)
    end

    def path
      nil
    end

    private

    attr_reader :password

    def client
      @client ||= client_for_site(content_url)
    end

    def client_for_site(_content_url)
      Client.new(server_url, username, password, _content_url, api_version, token_lifetime, @logger, impersonation_user_id)
    end

    def site_id
      admin_client.get_collection(Resources::Site.location(path)).each do |site|
        if site.content_url == content_url
          return site.id
        end
      end
    end

    def impersonation_user_id
      return @impersonation_user_id if @impersonation_user_id
      return nil unless impersonation_username
      user = admin_client.get(Resources::Site.location(path, site_id)).users(filter: ["name:eq:#{impersonation_username}"]).first
      return @impersonation_user_id = user.id if user
      raise TableauServerClientError.new("User '#{username}' not found.")
    end

    def admin_client
      @admin_client ||= Client.new(server_url, username, password, content_url, api_version, token_lifetime, @logger, nil)
    end

  end
end
