require 'tableau_server_client/client'
require 'tableau_server_client/credentials'
require 'tableau_server_client/resources/site'
require 'tableau_server_client/resources/schedule'
require 'tableau_server_client/exception'
require 'logger'

module TableauServerClient
  class Server

    DEFAULT_API_VERSION = "3.21"

    # Sign in with either username/password or a Personal Access Token (required by Tableau Cloud).
    # Please note that some methods can't be used with Tableau Cloud.
    def initialize(server_url, username = nil, password = nil,
                   content_url: "", api_version: DEFAULT_API_VERSION, token_lifetime: 240,
                   log_level: :info, impersonation_username: nil,
                   personal_access_token_name: nil, personal_access_token_secret: nil)
      @server_url = server_url
      @content_url = content_url
      @api_version = api_version
      @token_lifetime = token_lifetime
      @logger = ::Logger.new(STDOUT)
      @logger.level = ::Logger.const_get(log_level.upcase.to_sym)
      @impersonation_username = impersonation_username
      @credentials = build_credentials(username, password,
                                       personal_access_token_name, personal_access_token_secret)

      if impersonation_username && !@credentials.supports_impersonation?
        raise Credentials::UnsupportedOperationError.new(
          "Impersonation is not supported when signing in with a Personal Access Token. " \
          "It requires username/password credentials and is Tableau Server only."
        )
      end
    end

    attr_reader :server_url, :content_url, :api_version, :token_lifetime, :logger, :impersonation_username

    # Tableau Server only: lists every site on the server. Not available on Tableau Cloud,
    # where you can only access the site you signed in to. Use #current_site instead.
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

    def current_site
      client.get Resources::Site.location(path, client.token.site_id)
    end

    def full_site(id)
      client_for_site(client.get(Resources::Site.location(path, id)).content_url).get Resources::Site.location(path, id)
    end

    # Tableau Server only: server-wide schedules. Tableau Cloud manages schedules per extract-refresh task (custom frequencies)
    # and returns 403 for this endpoint.
    def schedules
      client.get_collection Resources::Schedule.location(path)
    end

    def path
      nil
    end

    private

    def build_credentials(username, password, token_name, token_secret)
      if token_name || token_secret
        unless token_name && token_secret
          raise TableauServerClientError.new(
            "Both personal_access_token_name and personal_access_token_secret are required for PAT sign-in."
          )
        end
        Credentials::PersonalAccessToken.new(token_name:, token_secret:)
      else
        unless username && password
          raise TableauServerClientError.new(
            "Provide either username/password or a Personal Access Token to sign in."
          )
        end
        Credentials::Password.new(username:, password:)
      end
    end

    def client
      @client ||= client_for_site(content_url)
    end

    def client_for_site(_content_url)
      Client.new(server_url, @credentials, _content_url, api_version, token_lifetime, @logger, impersonation_user_id)
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
      raise TableauServerClientError.new("User '#{impersonation_username}' not found.")
    end

    def admin_client
      @admin_client ||= Client.new(server_url, @credentials, content_url, api_version, token_lifetime, @logger, nil)
    end

  end
end
