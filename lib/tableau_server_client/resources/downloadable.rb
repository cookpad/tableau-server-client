module TableauServerClient
  module Resources

      module Downloadable

        def download(file_path: nil)
          response = client.download(location(query_params: {"includeExtract": "False"}), file_path: file_path)
          type, disposition = response.headers.values_at('content-type', 'content-disposition')
          case type
          when 'application/xml'
            return Nokogiri::XML(response.body)
          when 'application/octet-stream'
            Zip::InputStream.open(StringIO.new(response.body)) do |io|
              while entry = io.get_next_entry
                return Nokogiri::XML(io.read) if entry.name =~ /.*\.(tds|twb)/
              end
              raise "TDS or TWB file not found for: #{location.path}"
            end
          else
            raise "Unknown content-type: #{type}"
          end
        end
    end

  end
end
