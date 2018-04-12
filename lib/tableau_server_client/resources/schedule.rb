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
          id = s.xpath("//xmlns:schedule/@id")[0].value
          yield from_response(client, path, s)
        end
      end

    end
  end
end
