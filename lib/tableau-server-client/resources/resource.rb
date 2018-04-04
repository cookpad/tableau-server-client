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
        self.name.split("::").last.downcase
      end

      def self.location(prefix, id=nil, filter: [])
        path = [prefix, "#{resource_name}s", id].compact.join("/")
        Location.new(self, path, filter)
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

      def site_path
        self.class.extract_site_path(path)
      end

      class Location

        def initialize(klass, path, filter)
          @klass = klass
          @path = path
          @filter = filter
        end

        attr_reader :klass, :path

        def filter
          @filter.empty? ? {} : {filter: @filter.join(",")}
        end

        def query_params
          filter
        end
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
