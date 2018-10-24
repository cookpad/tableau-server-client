require 'tableau_server_client/resources/resource'

module TableauServerClient
  module Resources

    class Schedule < Resource

      attr_reader :id, :name, :state, :priority, :created_at, :updated_at, :type, :frequency, :next_run_at

      def self.from_response(client, path, xml)
        attrs = extract_attributes(xml)
        new(client, path, attrs)
      end

      def self.from_collection_response(client, path, xml)
        xml.xpath("//xmlns:schedules/xmlns:schedule").each do |s|
          id = s.xpath("@id").first.value
          yield from_response(client, "#{path}/#{id}", s)
        end
      end

      def tasks(site)
        site.extract_refreshes.select {|t| t.schedule_id == id }
      end

      def run_now(site)
        tasks(site).map {|t| t.run_now }
      end

    end
  end
end
