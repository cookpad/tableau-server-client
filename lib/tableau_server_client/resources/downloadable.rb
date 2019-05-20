module TableauServerClient
  module Resources

      module Downloadable

        def download(file_path: nil)
          return @content_body if @content_body and (file_path.nil? or @file_path == file_path)
          @file_path = file_path
          response = client.download(location(query_params: {"includeExtract": "False"}), file_path: file_path)
          content_type = response.headers['content-type']
          case content_type
          when 'application/xml'
            return @content_body = Nokogiri::XML(response.body)
          when 'application/octet-stream'
            Zip::InputStream.open(StringIO.new(response.body)) do |io|
              while entry = io.get_next_entry
                return @content_body = Nokogiri::XML(io.read) if entry.name =~ /.*\.(tds|twb)/
              end
              raise "TDS or TWB file not found for: #{location.path}"
            end
          else
            raise "Unknown content-type: #{content_type}"
          end
        end
    end

  end
end
