require 'tableau-server-client/resources/resource'

module TableauServerClient
  module Resources

    class Connection < Resource

      attr_reader :id, :type, :server_address, :server_port, :user_name, :password, :embed_password
      attr_writer :user_name, :password, :embed_password

      def self.from_response(client, path, xml)
        attrs = extract_attributes(xml)
        new(client, path, attrs)
      end

      def self.from_collection_response(client, path, xml)
        xml.xpath("//xmlns:connections/xmlns:connection").each do |s|
          id = s['id']
          yield from_response(client, "#{path}/#{id}", s)
        end
      end

      def to_request
        request = build_request {|b|
          b.connection(serverAddress: server_address, serverPort: server_port,
                       userName: user_name, password: password, embedPassword: embed_password)
        }
      end

      def update!
        @client.update self
      end

    end

  end
end
