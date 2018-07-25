require 'tableau_server_client/resources/resource'

module TableauServerClient
  module Resources

    class Project < Resource

      attr_reader :id, :name, :description, :parent_project_id

      def self.from_response(client, path, xml)
        attrs = extract_attributes(xml)
        new(client, path, attrs)
      end

      def self.from_collection_response(client, path, xml)
        xml.xpath("//xmlns:projects/xmlns:project").each do |s|
          id = s['id']
          yield from_response(client, "#{path}/#{id}", s)
        end
      end

      def reload
        prjs = @client.get_collection Project.location(site_path, filter: ["name:eq:#{name}"])
        prjs.select {|p| p.id == id }.first
      end

      def redshift_username
        if md = description.match(/^REDSHIFT_USERNAME: (.+)$/)
          return md[1]
        end
      end

      def root_project?
        self.parent_project_id.nil?
      end

      def root_project
        parent_projects[0] || self
      end

      def parent_projects
        return @parent_projects if @parent_projects
        @parent_projects = []
        curr_pj = self
        pjs = @client.get_collection Project.location(site_path)
        while ! curr_pj.root_project?
          pjs.each do |pj|
            if pj.id == curr_pj.parent_project_id
              @parent_projects.unshift pj
              curr_pj = pj
              break
            end
          end
        end
        return @parent_projects
      end

      def hierarchy
        (parent_projects << self).map {|p| p.name }.join('/')
      end

      def extract_values_in_description
        @values_in_description ||=\
          description.lines.map { |l|/^(.*):\s*(.*)$/.match(l) }.reject { |m| m.nil? }.map { |m| m[1,2] }.to_h
      end

      def extract_value_in_description(key)
        extract_values_in_description[key]
      end

    end
  end
end
