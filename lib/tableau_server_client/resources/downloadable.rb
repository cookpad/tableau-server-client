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
            Zip::File.open_buffer(StringIO.new(response.body)) do |zip|
              entry = zip.find { |e| e.name =~ /.*\.(tds|twb)/ }
              raise "TDS or TWB file not found for: #{location.path}" unless entry
              return @content_body = Nokogiri::XML(entry.get_input_stream.read)
            end
          else
            raise "Unknown content-type: #{content_type}"
          end
        end
    end

  end
end
