require 'tableau_server_client/resources/resource'
require 'tableau_server_client/resources/project'
require 'tableau_server_client/resources/connection'

module TableauServerClient
  module Resources

    class Datasource < Resource

      attr_reader :id, :name, :content_url, :type, :created_at, :updated_at, :is_certified, :project, :owner

      def self.from_response(client, path, xml)
        attrs = extract_attributes(xml)
        project = xml.xpath("xmlns:project")[0]
        site_path = extract_site_path(path)
        project_path = "#{site_path}/projects/#{project['id']}"
        attrs['project'] = Project.from_response(client, project_path, project)
        #TODO add owner
        new(client, path, attrs)
      end

      def self.from_collection_response(client, path, xml)
        xml.xpath("//xmlns:datasources/xmlns:datasource").each do |s|
          id = s['id']
          yield from_response(client, "#{path}/#{id}", s)
        end
      end

      def connections
        @client.get_collection Connection.location(path)
      end

    end
  end
end
