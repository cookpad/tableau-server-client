require 'tableau_server_client/resources/resource'
require 'tableau_server_client/resources/project'
require 'tableau_server_client/resources/connection'
require 'tableau_server_client/resources/downloadable'

module TableauServerClient
  module Resources

    class Datasource < Resource
      include Downloadable

      attr_reader :id, :name, :webpage_url, :content_url, :type, :created_at, :updated_at, :is_certified
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

      def content
        DatasourceContent.new(download.xpath('//datasource').first)
      end

      class DatasourceContent

        def initialize(xml)
          @xml = xml
        end

        attr_reader :xml

        NamedConnection = Struct.new("NamedConnections", :class, :caption, :name)
        def named_connections
          xml.xpath('//named-connection').map do |c|
            NamedConnection.new(c.first_element_child['class'], c['caption'], c['name'])
          end
        end

        def custom_queries
          relations.select {|r| r['type'] == 'text' }.map {|c| c.content }
        end

        def tables
          tables  = []
          redshift_connections = named_connections.select {|c| c.class == 'redshift' }.map {|c| c.name }
          relations.each do |rel|
            next unless redshift_connections.include? rel['connection']
            case rel['type']
            when 'table'
              tables << rel['table']
            when 'text'
              tables.concat extract_tables(rel.content)
            else
              next
            end
          end
          tables.map {|t| t.gsub(/[\[\]")]/, '')}.uniq
        end

        private

        def relations
          xml.xpath('//relation')
        end

        def extract_tables(query)
          q = query.dup
          q.gsub!(/(\<\[Parameters\]\.\[.*?\]\>)/, "'\\1'")
          q.gsub!(/(--[^\r\n]*)|(\/\*[\w\W]*?(?=\*\/)\*\/)/m, '')
          q.gsub!(/[\t\r\n]/, ' ')
          q.gsub!(/\s+/, ' ')

          tables = []
          may_be_table = false
          q.split(' ').each do |t|
            t.downcase!
            if may_be_table
              tables << t unless t =~ /(^select|^\(.*)/
              may_be_table = false
            end
            if ['from', 'join'].include?(t)
               may_be_table = true
            end
          end
          tables
          # ParseError with sub-query without alias name
          #PgQuery.parse(no_parameter_query).tables.each do |t|
          #  yield t
          #end
        end
      end

    end
  end
end
