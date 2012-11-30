require 'open-uri'
require 'net/http'
require 'nokogiri'

require 'hidemyass/version'
require 'hidemyass/ip'
require 'hidemyass/http'
require 'hidemyass/logger'
require 'hidemyass/railtie' if defined?(Rails)

module HideMyAss
  extend Logger

  SITE     = "http://hidemyass.com".freeze
  # TODO: Find a way to get ideal results in the custom search
  ENDPOINT = "http://hidemyass.com/proxy-list/search-750598".freeze

  LOG_PREFIX = '** [hidemyass] '
  
  HTTP_ERRORS = [Timeout::Error,
                 Errno::EINVAL,
                 Errno::ECONNRESET,
                 Errno::ECONNREFUSED,
                 EOFError,
                 Net::HTTPBadResponse,
                 Net::HTTPHeaderSyntaxError,
                 Net::ProtocolError]
                 
   def self.options
     @options ||= {
       :log => true,
       :local => false,
       :clear_cache => false
     }
   end

  def self.proxies
    clear_cache if options[:clear_cache]
    html = Nokogiri::HTML(open(URI.parse(ENDPOINT))) unless @proxies

    @proxies ||= html.xpath('//table[@id="listtable"]/tr').collect do |node|
      ip = HideMyAss::IP.new(node.at_xpath('td[2]/span'))
      next unless ip.valid?
      { 
        host: ip.address,
        port: node.at_xpath('td[3]').content.strip
      }
    end
  end
  
  def self.clear_cache
    @proxies = nil
  end
end