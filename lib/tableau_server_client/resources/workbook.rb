require 'tableau_server_client/resources/resource'
require 'tableau_server_client/resources/project'
require 'tableau_server_client/resources/connection'
require 'tableau_server_client/resources/downloadable'
require 'tableau_server_client/resources/datasource'
require 'tableau_server_client/resources/view'

module TableauServerClient
  module Resources

    class Workbook < Resource
      include Downloadable

      attr_reader :id, :name, :webpage_url, :content_url, :show_tabs, :size, :created_at, :updated_at, :project_id, :owner_id, :tags
      attr_writer :owner

      def self.from_response(client, path, xml)
        attrs = extract_attributes(xml)
        attrs['project_id'] = xml.xpath("xmlns:project")[0]['id']
        attrs['owner_id'] = xml.xpath("xmlns:owner")[0]['id']
        attrs['tags'] = xml.xpath("xmlns:tags/xmlns:tag").map {|t| t['label'] }
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

      def project
        @project ||= @client.get_collection(Project.location(site_path)).find {|p| p.id == project_id }
      end

      def owner
        @owner ||= @client.get User.location(site_path, @owner_id)
      end

      def views
        @views ||= @client.get_collection(View.location(site_path)).select {|v| v.workbook_id == id }
      end

      def to_request
        request = build_request {|b|
          b.workbook {|w|
            w.owner(id: owner.id)
          }
        }
        request
      end

      def update!
        @client.update self
      end

      def add_tags!(tags)
        request = build_request {|b|
          b.tags {
            tags.each do |t|
              b.tag(label: t)
            end
          }
        }
        resp = @client.update(self, path: "#{path}/tags", request: request)
      end

      def delete_tag!(tag)
        @client.delete(self, path: "#{path}/tags/#{tag}")
      end

      def embedded_datasources
        download.xpath('//datasources//datasource').map do |ds|
          Datasource::DatasourceContent.new(ds)
        end
      end

    end
  end
end
