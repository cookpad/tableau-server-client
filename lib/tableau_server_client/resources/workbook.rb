require 'tableau_server_client/resources/resource'
require 'tableau_server_client/resources/project'
require 'tableau_server_client/resources/connection'

module TableauServerClient
  module Resources

    class Workbook < Resource

      attr_reader :id, :name, :content_url, :show_tabs, :size, :created_at, :updated_at, :project, :owner

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
        xml.xpath("//xmlns:workbooks/xmlns:workbook").each do |s|
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
