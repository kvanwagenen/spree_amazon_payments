require 'jeff'
require 'httparty'

module SpreeAmazonPayments
  class AmazonFps
    def self.valid_signature?(request)

      # Get endpoint
      endpoint = request.original_url

      # Get http parameters
      http_parameters = Rack::Utils.escape(request.params.except(*request.path_parameters.keys).to_query)

      # Build query
      amazon_payments = Spree::PaymentMethod.find_by_type("Spree::Gateway::AmazonPayments")
      query_params = {
        "AWSAccessKeyId" => amazon_payments.preferred_aws_access_key_id,
        "Action" => "VerifySignature",
        "UrlEndPoint" => endpoint,
        "HttpParameters" => http_parameters,
        "SignatureMethod" => "HmacSHA256",
        "SignatureVersion" => 2,
        "Timestamp" => Time.now.utc.iso8601,
        "Version" => "2008-09-17"
      }

      # Sign
      signature = ::Jeff::Signer.new("GET", "ftp.amazonaws.com", "/", query_params.to_query).sign_with(amazon_payments.preferred_aws_secret_access_key)
      
      # Make request
      response = HTTParty.post("https://fps.amazonaws.com?#{query_params.merge('Signature' => signature).to_query}")

      # Check for successful response
      status_el = Nokogiri::XML(response.body).css("VerificationStatus").first
      !status_el.nil? && status_el.inner_html == "Success"
    end
  end
end