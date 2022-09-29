
class APIException < StandardError

    # An error occurred while processing an API the request.

    attr_reader :status_code
    attr_reader :hint
    attr_reader :arg_errors

    def initialize(status_code, hint=nil, arg_errors=nil)

        # The status code associated with the error
        @status_code = status_code

        # A hint providing additional information as to why this error
        # occurred.
        @hint = hint

        # A dictionary of errors relating to the arguments (parameters) sent
        # to the API endpoint (e.g `{'arg_name': ['error1', ...]}`).
        @arg_errors = arg_errors

        super()
    end

    def APIException.get_class_by_status_code(error_type, default=nil)

        class_map = {
            400 => InvalidRequest,
            401 => Unauthorized,
            403 => Forbidden,
            405 => Forbidden,
            404 => NotFound,
            429 => RateLimitExceeded
        }

        if class_map.has_key? error_type
            return class_map[error_type]

        elsif default
            return default

        end

        return APIException

    end

end

class Forbidden < APIException

    # The request is not not allowed, most likely the HTTP method used to call
    # the API endpoint is incorrect or the API key (via its associated account)
    # does not have permission to call the endpoint and/or perform the action.

end

class InvalidRequest < APIException
    # Not a valid request, most likely a missing or invalid parameter.
end

class NotFound < APIException

    # The endpoint you are calling or the document you referenced doesn't exist.

end

class RateLimitExceeded < APIException

    # You have exceeded the number of API requests allowed per second.

end

class Unauthorized < APIException

    # The API credentials provided are not valid.

end
