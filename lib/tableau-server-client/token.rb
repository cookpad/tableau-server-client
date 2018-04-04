require 'nokogiri'

module TableauServerClient

  class Token

    def initialize(site_id, user_id, token, lifetime, created_at = Time.now)
      @site_id = site_id
      @user_id = user_id
      @token = token
      @lifetime = lifetime
      @created_at = created_at
    end

    attr_reader :site_id, :user_id, :token

    def self.parse(xml, lifetime)
      cred = Nokogiri::XML(xml).xpath("//xmlns:credentials")
      sid = cred.xpath("//xmlns:site")[0]['id']
      uid = cred.xpath("//xmlns:user")[0]['id']
      new(sid, uid, cred[0]['token'], lifetime)
    end

    SAFETY_BUFFER_MIN = 10

    def valid?
      Time.now < @created_at + (@lifetime + SAFETY_BUFFER_MIN) * 60
    end

    def to_s
      @token
    end

  end

end
