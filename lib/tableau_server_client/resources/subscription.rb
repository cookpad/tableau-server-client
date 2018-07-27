require 'tableau_server_client/resources/resource'

module TableauServerClient
  module Resources

    class Subscription < Resource

      attr_reader :id, :subject

      def self.from_response(client, path, xml)
        attrs = extract_attributes(xml)
        attrs['content_id'] = xml.xpath("xmlns:content")[0]['id']
        attrs['schedule_id'] = xml.xpath("xmlns:schedule")[0]['id']
        attrs['user_id']   = xml.xpath("xmlns:user")[0]['id']
        new(client, path, attrs)
      end

      def self.from_collection_response(client, path, xml)
        xml.xpath("//xmlns:subscriptions/xmlns:subscription").each do |s|
          id = s['id']
          yield from_response(client, "#{path}/#{id}", s)
        end
      end

      def content
        raise NotImplementedError
      end

      def schedule
        @schedule ||= @client.get_collection(Schedule.location(nil)).find {|s| s.id == @schedule_id }
      end

      def user
        @user ||= @client.get User.location(site_path, @user_id)
      end

    end
  end
end
