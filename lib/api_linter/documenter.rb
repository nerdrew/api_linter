require 'active_support/inflector'
require 'erb'

module APILinter
  class Documenter

    def initialize(linter)
      @linter = linter
    end

    def api_documentation
      description = "\n#{linter.description}\n" if linter.description
      if linter.title
        title = "#{linter.title}: #{linter.method} #{route}"
      else
        title = "#{method} #{route}"
      end

      <<-API.gsub(/^ {8}/, '').chomp
        ## #{title}
        #{description}
        ### Request

        #### Headers
        #{formatted_request_headers.join "\n"}

        #### Body
        ```json
        #{request_documentation}
        ```

        ### Response

        #### Headers
        #{formatted_response_headers.join "\n"}

        #### Body
        ```json
        #{response_documentation}
        ```

        Example:
        ```
        #{sample}
        ```
      API
    end

    def request_documentation
      JSON.pretty_generate generate_documentation(request_params)
    end

    def response_documentation
      JSON.pretty_generate generate_documentation(response_params)
    end

    def formatted_request_headers
      request_headers.map do |key, value|
        "#{key}: #{value}"
      end
    end

    def formatted_response_headers
      response_headers.map do |key, value|
        "#{key}: #{value}"
      end
    end

    def sample
      # TODO only shows a basic auth sample
      if username && password
        auth = "-u '#{username}:#{password}' "
      end

      # TODO headers are not linted, nor handled correctly
      unless request_headers.empty?
        req_headers = "-H '#{formatted_request_headers.join("' -H '")}' "
      end
      unless response_headers.empty?
        res_headers = "#{formatted_response_headers.join("\n")}\n"
      end

      <<-CURL.gsub(/^ {8}/, '').chomp
        curl -i -H 'Content-Type: application/json' #{req_headers}#{auth}-X POST http://localhost:3000#{route} -d '
        #{JSON.pretty_generate sample_request_params}
        '

        HTTP/1.1 #{status} #{Rack::Utils::HTTP_STATUS_CODES[status]}
        #{res_headers}
        #{JSON.pretty_generate sample_response_params}
      CURL
    end

    def generate_documentation(filters)
      params = {}
      filters.each do |field, value|
        key = Key.parse field
        if Class === value
          params[key.extended_name] = value.to_s
        elsif value.nil?
          params[key.extended_name] = 'nil'
        elsif value.is_a?(Array) && value.all? {|value| Class === value || value.nil? }
          classes = value.map do |klass|
            klass.nil? ? 'nil' : ActiveSupport::Inflector.pluralize(klass.to_s)
          end.join(', ')
          params[key.extended_name] = "Array of #{classes}"
        elsif Hash === value
          params[key.extended_name] = generate_documentation(value)
        else
          raise
        end
      end
      params
    end
  end
end
