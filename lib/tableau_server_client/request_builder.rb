require 'nokogiri'

module TableauServerClient
  module RequestBuilder

    def build_request
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest {
          yield xml
        }
      end
      builder.to_xml
    end

  end
end
