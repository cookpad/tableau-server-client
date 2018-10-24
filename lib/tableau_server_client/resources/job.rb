require 'tableau_server_client/resources/resource'

module TableauServerClient
  module Resources

    class Job < Resource

      attr_reader :id, :mode, :type

      def self.from_response(client, path, xml)
        attrs = extract_attributes(xml)
        new(client, path, attrs)
      end

    end
  end
end
