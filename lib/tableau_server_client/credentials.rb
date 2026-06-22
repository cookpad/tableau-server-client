require 'tableau_server_client/exception'

module TableauServerClient
  module Credentials

    class UnsupportedOperationError < TableauServerClientError; end

    Password = Data.define(:username, :password) do
      def signin_attributes
        { name: username, password: password }
      end

      def supports_impersonation?
        true
      end

      def inspect
        "#<data #{self.class.name} username=#{username.inspect}, password=[REDACTED]>"
      end
      alias_method :to_s, :inspect
    end

    PersonalAccessToken = Data.define(:token_name, :token_secret) do
      def signin_attributes
        {
          personalAccessTokenName: token_name,
          personalAccessTokenSecret: token_secret,
        }
      end

      def supports_impersonation?
        false
      end

      def inspect
        "#<data #{self.class.name} token_name=#{token_name.inspect}, token_secret=[REDACTED]>"
      end
      alias_method :to_s, :inspect
    end
  end
end
