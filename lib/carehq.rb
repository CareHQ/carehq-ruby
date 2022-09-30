require 'digest'
require 'httparty'


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

        # Build the signature
        signature_data = method.downcase == 'get' ? params : data

        signature_values = []
        (signature_data or {}).each_pair do |key, value|
            signature_values.push(key)
            if value.kind_of?(Array)
                signature_values.concat(value)
            else
                signature_values.push(value)
            end
        end

        signature_body = signature_values.join ''

        timestamp = Time.now.to_f.to_s

        signature_hash = Digest::SHA1.new
        signature_hash.update timestamp
        signature_hash.update signature_body
        signature_hash.update @api_secret
        signature = signature_hash.hexdigest

        # Build the headers
        headers = {
            'Accept' => 'application/json',
            'X-CareHQ-AccountId' => @account_id,
            'X-CareHQ-APIKey' => @api_key,
            'X-CareHQ-Signature' => signature,
            'X-CareHQ-Timestamp' => timestamp
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

end

require 'carehq/exceptions'
