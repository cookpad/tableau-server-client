require 'tableau_server_client/resources/resource'

module TableauServerClient
  module Resources

    class User < Resource

      attr_reader :id, :name, :site_role, :last_login, :external_auth_user_id, :full_name

      def self.from_response(client, path, xml)
        attrs = extract_attributes(xml)
        new(client, path, attrs)
      end

      def self.from_collection_response(client, path, xml)
        xml.xpath("//xmlns:users/xmlns:user").each do |s|
          id = s['id']
          yield from_response(client, "#{path}/#{id}", s)
        end
      end

      def reload
        @client.get User.location(site_path, id)
      end

      def full_name
        @full_name ||= self.reload.full_name
      end

      def workbooks
        @client.get_collection(Workbook.location(site_path, filter: ["ownerName:eq:#{full_name}"])).select do |w|
          w.owner.id == id
        end
      end

      def datasources
        @client.get_collection(Datasource.location(site_path, filter: ["ownerName:eq:#{full_name}"])).select do |d|
          d.owner.id == id
        end
      end

    end
  end
end
