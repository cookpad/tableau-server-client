require 'tableau_server_client/resources/resource'
require 'tableau_server_client/resources/connection'
require 'tableau_server_client/resources/job'

module TableauServerClient
  module Resources

    class ExtractRefresh < Resource

      attr_reader :id, :priority, :consecutive_failed_count, :type

      def self.from_response(client, path, xml)
        attrs = extract_attributes(xml)
        attrs['schedule_id'] = xml.xpath("xmlns:schedule/@id").first.value
        attrs['workbook_id'] = xml.xpath("xmlns:workbook/@id").first&.value
        attrs['datasource_id'] = xml.xpath("xmlns:datasource/@id").first&.value
        new(client, path, attrs)
      end

      def self.from_collection_response(client, path, xml)
        xml.xpath("//xmlns:tasks/xmlns:task/xmlns:extractRefresh").each do |s|
          id = s.xpath("@id").first.value
          yield from_response(client, "#{path}/#{id}", s)
        end
      end

      def self.plural_resource_name
        "extractRefreshes"
      end

      def schedule_id
        @schedule_id
      end

      def workbook_id
        @workbook_id
      end

      def datasource_id
        @datasource_id
      end

      def schedule
        @client.get_collection(Resources::Schedule.location(nil)).find {|s| s.id == schedule_id }
      end

      def workbook
        @client.get_collection(Workbook.location(site_path)).find {|w| w.id == workbook_id }
      end

      def datasource
        @client.get_collection(Datasource.location(site_path)).find {|d| d.id == datasource_id }
      end

      def run_now
        resp = @client.create(self, path: "#{path}/runNow", request: build_request {})
        job_id = resp.xpath("//xmlns:job/@id").first.value
        Job.from_response(@client, Job.location(site_path, id = job_id).path, resp)
      end

      def delete!
        resp = @client.delete(self)
      end

    end
  end
end
