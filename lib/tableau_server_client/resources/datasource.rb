require 'tableau_server_client/resources/resource'
require 'tableau_server_client/resources/project'
require 'tableau_server_client/resources/connection'

module TableauServerClient
  module Resources

    class Datasource < Resource

      attr_reader :id, :name, :content_url, :type, :created_at, :updated_at, :is_certified
      attr_writer :owner

      def self.from_response(client, path, xml)
        attrs = extract_attributes(xml)
        attrs['project_id'] = xml.xpath("xmlns:project")[0]['id']
        attrs['owner_id']   = xml.xpath("xmlns:owner")[0]['id']
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

      def project
        @project ||= @client.get_collection(Project.location(site_path)).find {|p| p.id == @project_id }
      end

      def owner
        @owner ||= @client.get User.location(site_path, @owner_id)
      end

      def to_request
        request = build_request {|b|
          b.datasource {|w|
            w.owner(id: owner.id)
          }
        }
      end

      def update!
        @client.update self
      end


    end
  end
end
