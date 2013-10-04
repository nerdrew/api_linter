require 'yajl/json_gem'

module APILinter
  class LintMiddleware

    def initialize(app, linters = {})
      @app = app
      APILinter::Linter.register_linters linters
    end

    def call(env)
      request = Rack::Request.new(env)
      linter = APILinter::Linter.for_route env['REQUEST_METHOD'], request.path_info

      status, headers, body = @app.call(env)

      if linter
        request_params = parse_request_params request
        response_params = parse_response_params headers, body

        linter.check sample_request_headers: {},
          sample_request_params: request_params,
          status: status,
          sample_response_headers: headers,
          sample_response_params: response_params,
          description: APILinter::Config.description,
          document: APILinter::Config.document?,
          strict: APILinter::Config.strict?
      end

      [status, headers, body]
    end

    private

    def parse_request_params(request)
      if request.content_type == 'application/json'
        request.params.merge JSON.parse request.body.read
      else
        request.params
      end
    end

    def parse_response_params(headers, body)
      if headers['Content-Type'] == 'application/json'
        JSON.parse body.join
      end
    end
  end
end
