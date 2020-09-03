require 'tableau_server_client/resources/resource'

module TableauServerClient
  module Resources

    class Group < Resource

      attr_reader :id, :name, :site_role

      def self.from_response(client, path, xml)
        attrs = extract_attributes(xml)
        if xml.xpath("xmlns:import")[0]
          attrs['site_role'] = xml.xpath("xmlns:import")[0]['siteRole']
        end
        new(client, path, attrs)
      end

      def self.from_collection_response(client, path, xml)
        xml.xpath("//xmlns:groups/xmlns:group").each do |s|
          id = s['id']
          yield from_response(client, "#{path}/#{id}", s)
        end
      end

      def users
        @client.get_collection(User.location(path))
      end

    end
  end
end
