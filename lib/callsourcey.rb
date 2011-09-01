# CallSourcey: Callsource provisioning and call details fetcher
# Handles connecting to the API and converting the XML into ruby hash using HTTParty
# Built for the Callsource XML service Version 6.0 (E) April 3, 2009

['uri', 'net/http', 'digest/md5', 'xmlsimple'].map { |lib| require lib }

class CallSourcey
  class MethodUnsupported < StandardError; end
  
  class << self
    
    def get(method, data = nil)
      csr  = CSRequest.new method, data
      resp = CSResponse.new post(csr.uri, csr.body), csr.method
      raise [csr, resp.data].pretty_inspect
    end
    
    # The XML tag name of the request and their corresponding reponse tag names
    def request_response_map
      @request_response_map ||= {
        'GetProvisioningInfoRequest' => 'GetProvisioningInfoResponse',
        'CustomerRequest' 					 => 'CustomerResponse',
        'CampaignRequest' 					 => 'CampaignResponse',
        'AddNumberToCampaignRequest' => 'AddNumberToCampaignResponse',
        'GetCallDetailsRequest'		   => 'GetCallDetailsResponse',
        'AdSourceRequest' 					 => 'AdSourceResponse',
        'SalesRepMappingRequest'		 => 'SalesRepResponse',
        'UserRequest'								 => 'UserResponse',
        'AdSourceInfoRequest'				 => 'AdSourceInfoResponse'
      }
    end
    
    def has_method?(method)
      request_response_map.keys.include? method
    end

    private

    # returns the http object. :uri: is a full url
    def connect(uri)
      uri = URI.parse uri
      Net::HTTP.new uri.host, uri.port
    end
    
    def post(uri, xml)
      puts "\n-----> Sending post request to #{uri}\n"
      connect(uri).request_post uri, "<?xml version='1.0'?>#{xml}"
    end
  end # << self
  
  #
  # Subclasses
  # CSRequest: builds the auth token and XML request body
  # CSResponse: handles the response from the service and converts it to a hash
  
  # Builds the request object and auth token, body returns the XML string for to send in the post request
  class CSRequest
    attr_reader :method, :body, :uri

    def initialize(method, data = nil, ops = {})
      @method = method.camelcase
      raise CallSourcey::MethodUnsupported, "<#{@method}> is not a supported method." unless CallSourcey.has_method? @method
      
      @user = ops[:user] || 'xmluser_usstorage'
      @pass = ops[:pass] || 'xmlapi1'
      @uri  = ops[:uri]  || 'http://provisioning.callsource.com/services/Provision'
      @data = convert data
      @service_tag = service_tag @data
      @body        = request_wrap
    end
    
    # XML Request posted to the call source service
    def request_wrap
      xml = <<-XML
<CallSource version="E">
<Username>#{@user}</Username> 
<Authentication>#{auth_token}</Authentication> 
#{@service_tag}
</CallSource>
      XML
      xml.strip!
    end
    
    # The service tag that wraps the method and data tags. This is used in the auth_token
    def service_tag(method_xml)
      "<CallSourceService>#{method_xml}</CallSourceService>"
    end

    private
    
    # A hash used by XmlSimple to convert into XML, the values are in arrays to let XmlSimple know it should make a node rather that an attribute
    def convert(hash)
      return '' if hash.nil?
      XmlSimple.xml_out(hash, { 'RootName' => @method, 'ContentKey' => 'content' }).strip
    end
    
    # Sent in every request. Formatted according to the XML services guide pg. 2
    def auth_token
      curtime = Time.now.utc.strftime '%Y%m%d%H' # yyyymmddhh. hh is 24 hour 0 padded
      token = "#{@user}-#{@pass}-#{curtime}-#{@service_tag}"
      puts "----> Generated auth token: #{token}"
      Digest::MD5.hexdigest(token).upcase
    end

  end # CSRequest
  
  class CSResponse
    attr_reader :body, :data, :ok
    
    def initialize(response, method)
      @body = convert response.body
      @data = @body['CallSourceService'][response_key(method)]
      @ok   = @data['status'].downcase == 'ok'
    end
    
    private
    
    # stips leading and trailing whitespace form the values in data
    def clean(data)
      data.inject({}) do |hash, (key, val)| 
        hash[key] = val.is_a?(Array) ? val.map { |v| clean v } : (val.is_a?(Hash) ? clean(val) : val.try(:strip))
        hash
      end
    end
    
    def response_key(method)
      CallSourcey.request_response_map[method]
    end
    
    # XML to Hash
    def convert(xml)
      XmlSimple.xml_in xml, 'ForceArray' => false
    end
    
  end # CSRequest
end
