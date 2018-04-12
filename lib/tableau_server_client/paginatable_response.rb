require 'nokogiri'

module TableauServerClient
  class PaginatableResponse
    include Enumerable

    def initialize(client, request_url, response)
      @client = client
      @request_url = request_url
      @response = response
    end

    def each
      yield @response
      return unless paginated?
      res = @response.dup
      url = @request_url.dup
      while true
        pgn = Pagination.parse(res.body)
        break unless pgn.next_page?
        res = @client.session.get url.merge_params!(pgn.request_params).to_s
        yield res
      end
    end

    def each_body
      each do |res|
        yield Nokogiri::XML(res.body)
      end
    end

    private

    def paginated?
      @paginated ||= !Pagination.parse(@response.body).nil?
    end

    class Pagination
      def initialize(page_number, page_size, total_available)
        @page_numner = page_number
        @page_size = page_size
        @total_available = total_available
      end

      def page_number
        @page_number.to_i
      end

      def page_size
        @page_size.to_i
      end

      def total_available
        @total_available.to_i
      end

      def self.parse(xml)
        pg = Nokogiri::XML(xml).xpath("//xmlns:pagination")[0]
        return nil unless pg
        Pagination.new(pg['pageNumber'], pg['pageSize'], pg['totalAvailable'])
      end

      def next_page?
        page_number * page_size > total_available
      end

      def request_params
        { pageSize: page_size, pageNumber: page_number + 1 }
      end
    end

  end
end
