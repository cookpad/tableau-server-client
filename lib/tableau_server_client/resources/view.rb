require 'tableau_server_client/resources/resource'
require 'tableau_server_client/resources/workbook'

module TableauServerClient
  module Resources

    class View < Resource

      attr_reader :id, :name, :content_url, :workbook_id
      attr_writer :owner

      def self.from_response(client, path, xml)
        attrs = extract_attributes(xml)
        attrs['workbook_id'] = xml.xpath("xmlns:workbook")[0]['id']
        new(client, path, attrs)
      end

      def self.from_collection_response(client, path, xml)
        xml.xpath("//xmlns:views/xmlns:view").each do |s|
          id = s['id']
          yield from_response(client, "#{path}/#{id}", s)
        end
      end

      def workbook
        client.get Workbook.location(site_path, workbook_id)
      end

      def webpage_url
        "#{server_url}#{content}/#/views/#{webpage_path}"
      end

      def webpage_path
        content_url.gsub('/sheets/', '/')
      end

      def image(query_params: {}, file_path: nil)
        return @image if @iamge
        @image = client.download_image(location(query_params: query_params), file_path: file_path)
        @image
      end

    end
  end
end
