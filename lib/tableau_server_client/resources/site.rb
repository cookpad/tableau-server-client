require 'tableau_server_client/resources/resource'
require 'tableau_server_client/resources/datasource'
require 'tableau_server_client/resources/workbook'
require 'tableau_server_client/resources/user'
require 'tableau_server_client/resources/subscription'
require 'tableau_server_client/resources/extract_refresh'
require 'tableau_server_client/resources/view'

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

      def views(filter: [])
        @client.get_collection View.location(path, filter: filter)
      end

      def users(filter: [])
        @client.get_collection User.location(path, filter: filter)
      end

      def user(id)
        @client.get User.location(path, id)
      end

      def projects(filter: [])
        @client.get_collection Project.location(path, filter: filter)
      end

      def project(id)
        projects.find { |p| p.id == id }
      end

      def subscriptions
        @client.get_collection Subscription.location(path)
      end

      def subscription(id)
        subscriptions.find {|s| s.id = id }
      end

      def extract_refreshes
        @client.get_collection ExtractRefresh.location("#{path}/tasks")
      end

    end
  end
end
