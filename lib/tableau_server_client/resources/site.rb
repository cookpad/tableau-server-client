require 'tableau_server_client/resources/resource'
require 'tableau_server_client/resources/datasource'
require 'tableau_server_client/resources/workbook'

module TableauServerClient
  module Resources

    class Site < Resource

      attr_reader :id, :name, :content_url, :admin_mode, :storage_quota, :state

      def self.from_response(client, path, xml)
        attrs = extract_attributes(xml)
        new(client, path, attrs)
      end

      def self.from_collection_response(client, path, xml)
        xml.xpath("//xmlns:sites/xmlns:site").each do |s|
          id = s['id']
          yield from_response(client, "#{path}/#{id}", s)
        end
      end

      def datasources(filter: [])
        @client.get_collection Datasource.location(path, filter: filter)
      end

      def datasource(id)
        @client.get Datasource.location(path, id)
      end

      def workbooks(filter: [])
        @client.get_collection Workbook.location(path, filter: filter)
      end

      def workbook(id)
        @client.get Workbook.location(path, id)
      end

    end
  end
end
