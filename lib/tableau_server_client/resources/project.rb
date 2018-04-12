require 'tableau_server_client/resources/resource'

module TableauServerClient
  module Resources

    class Project < Resource

      attr_reader :id, :name, :description, :content_permissions

      def self.from_response(client, path, xml)
        attrs = extract_attributes(xml)
        new(client, path, attrs)
      end

      def self.from_collection_response(client, path, xml)
        xml.xpath("//xmlns:projects/xmlns:project").each do |s|
          id = s['id']
          yield from_response(client, "#{path}/#{id}", s)
        end
      end

      def reload
        prjs = @client.get_collection Project.location(site_path, filter: ["name:eq:#{name}"])
        prjs.select {|p| p.id == id }.first
      end

      def redshift_username
        if md = description.match(/^REDSHIFT_USERNAME: (.+)$/)
          return md[1]
        end
      end

    end
  end
end
