module TableauServerClient
  module Resources

    class Resource
      include RequestBuilder

      def initialize(client, path, attributes)
        @client = client
        @path = path
        attributes.each {|k,v| instance_variable_set("@#{k}",v) }
      end

      def self.attr_reader(*vars)
          @attributes ||= []
          @attributes.concat (vars.map { |v| Attribute.new(v.to_s) })
          super(*vars)
      end

      def self.attributes
        @attributes
      end

      def self.resource_name
        self.name.split("::").last.sub(/./){ $&.downcase }
      end

      def self.plural_resource_name
        "#{self.resource_name}s"
      end

      def self.location(prefix, id=nil, filter: [])
        path = [prefix, plural_resource_name, id].compact.join("/")
        Location.new(self, path, filter.empty? ? {} : {filter: filter.join(',')})
      end

      def self.extract_attributes(xml)
        unless xml.name == resource_name
          raise "Element name (#{xml.name}) does not match with resource name (#{resource_name})"
        end
        attributes.select {|a| xml.key?(a.camelCase) }.map {|a| [a.to_sym, xml[a.camelCase]] }.to_h
      end

      def self.extract_site_path(path)
        p = path.split('/')
        p.slice(p.index('sites'),2).join('/')
      end

      def attributes
        self.class.attributes
      end

      def path
        @path
      end

      def location(query_params: {})
        Location.new(self, path, query_params)
      end

      def site_path
        self.class.extract_site_path(path)
      end

      def delete!
        @client.delete self
      end

      class Location

        def initialize(klass, path, query_params)
          @klass = klass
          @path = path
          @query_params = query_params
        end

        attr_reader :klass, :path, :query_params
      end

      class Attribute < String

        def camelCase
         atr = self.split("_").map{ |w| w.capitalize }.join
         atr[0] = atr[0].downcase
         atr
        end

      end

    end

  end
end
