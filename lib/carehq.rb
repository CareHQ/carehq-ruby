require 'digest'
require 'httparty'
require 'securerandom'
require 'openssl'

require 'carehq/exceptions'

class HTTPartyWrapper
    include HTTParty

    query_string_normalizer proc {|query|
        query.map do |key, value|
            value.kind_of?(Array) ?
                value.map {|v| "#{key}=#{v}"} : "#{key}=#{value}"
        end.join('&')
    }
end


class APIClient

    # A client for the CareHQ API.

    attr_reader :rate_limit
    attr_reader :rate_limit_reset
    attr_reader :rate_limit_remaining

    def initialize(
        account_id,
        api_key,
        api_secret,
        api_base_url: 'https://api.carehq.co.uk',
        timeout: nil
    )

        # The Id of the CareHQ account the API key relates to
        @account_id = account_id

        # A key used to authenticate API calls to an account
        @api_key = api_key

        # A secret used to generate a signature for each API request
        @api_secret = api_secret

        # The base URL to use when calling the API
        @api_base_url = api_base_url

        # The period of time before requests to the API should timeout
        @timeout = timeout

        # NOTE: Rate limiting information is only available after a request
        # has been made.

        # The maximum number of requests per second that can be made with the
        # given API key.
        @rate_limit = nil

        # The time (seconds since epoch) when the current rate limit will
        # reset.
        @rate_limit_reset = nil

        # The number of requests remaining within the current limit before the
        # next reset.
        @rate_limit_remaining = nil
    end

    def request(method, path, params: nil, data: nil)
        # Call the API

        # Filter out params/data set to `nil` and ensure all arguments are
        # converted to strings.

        if params
            params.delete_if {|k, v| v.nil?}
        end

        if data
            data.delete_if {|k, v| v.nil?}
        end

        # Build the signature (v2)
        timestamp_str = Time.now.to_i.to_s
        nonce = SecureRandom.urlsafe_base64(16)

        canonical = _canonical_params_str(method.upcase == 'GET' ? params : data)

        string_to_sign = [
            timestamp_str,
            nonce,
            method.upcase,
            "/v1/#{path}",
            canonical
        ].join("\n")

        signature = _compute_signature(@api_secret, string_to_sign)

        # Build the headers
        headers = {
            'Accept' => 'application/json',
            'X-CareHQ-AccountId' => @account_id,
            'X-CareHQ-APIKey' => @api_key,
            'X-CareHQ-Nonce' => nonce,
            'X-CareHQ-Signature' => signature,
            'X-CareHQ-Signature-Version' => '2.0',
            'X-CareHQ-Timestamp' => timestamp_str
        }

        # Make the request
        url = [@api_base_url, '/v1/', path].join ''
        response = HTTPartyWrapper.method(method.downcase).call(
            url,
            {
                :query => params,
                :headers => headers,
                :body => data,
                :timeout => @timeout
            }
        )

        # Raise an error related to the response

        # Handle a successful response
        if [200, 204].include? response.code
            return response
        end

        error_cls = APIException.get_class_by_status_code(response.code)
        raise error_cls.new(
            response.code,
            response['hint'],
            response['arg_errors']
        )

    end

    private

    def _canonical_params_str(params)
        params ||= {}

        parts = []
        params.keys.sort.each do |key|
            values = params[key]
            values = [values] unless values.is_a?(Array) || values.is_a?(Set)
            values.sort.each do |value|
                parts << "#{key}=#{value}"
            end
        end

        parts.join("\n")
    end

    def _compute_signature(secret, msg)
        OpenSSL::HMAC.hexdigest('sha256', secret.to_s, msg.to_s)
    end
end
