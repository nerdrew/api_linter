module APILinter
  class Sample
    attr_writer :document, :strict

    attr_reader :sample_request_params, :sample_response_params,
      :sample_request_headers, :sample_response_headers,
      :request_params, :response_params,
      :status, :description

    def initialize(options = {})
      @sample_request_params = options[:sample_request_params] || {}
      @sample_response_params = options[:sample_response_params] || {}
      @sample_request_headers = options[:sample_request_headers] || {}
      @sample_response_headers = options[:sample_response_headers] || {}
      @status = options[:status]
      @description = options[:description]
      # TODO header linting
      #request_headers = options.delete(:request_headers) || {}
      #response_headers = options.delete(:response_headers) || {}

      @request_params = options[:request_params] || {}
      @response_params = options[:response_params] || {}
    end

    def results
      @@results_template ||= begin
        template_file = File.join(File.expand_path('..', __FILE__), 'templates', 'sample_results.md.erb')
        ERB.new File.read template_file
      end
      @@results_template.result binding
    end

    def request_passed?
      missing_request_params.empty? &&
        unpermitted_request_params.empty? &&
        request_type_mismatches.empty?
    end

    def response_passed?
      missing_response_params.empty? &&
        unpermitted_response_params.empty? &&
        response_type_mismatches.empty?
    end

    def document(method, route, username = nil, password = nil)
      # TODO only shows a basic auth sample
      if username && password
        auth = "-u '#{username}:#{password}' "
      end

      # TODO headers are not linted, nor handled correctly
      unless sample_request_headers.empty?
        req_headers = "-H '#{formatted_headers(sample_request_headers).join("' -H '")}' "
      end
      unless sample_response_headers.empty?
        res_headers = "#{formatted_headers(sample_response_headers).join("\n")}\n"
      end

      @@document_template ||= begin
        template_file = File.join(File.expand_path('..', __FILE__), 'templates', 'sample.md.erb')
        ERB.new File.read template_file
      end
      @@document_template.result binding
    end

    %w(
      missing_response_params unpermitted_response_params response_type_mismatches
      missing_request_params unpermitted_request_params request_type_mismatches
    ).each do |meth|
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{meth}
          if @#{meth}
            @#{meth}
          else
            verify!
            @#{meth}
          end
        end
      CODE
    end

    private

    def lint_hash(params, fields, missing_params = [], unpermitted_params = [], tracker = nil, type_mismatches = [])
      params = params.is_a?(Hash) ? params : {}

      tracker ||= params.deep_dup
      tracker = tracker.is_a?(Hash) ? tracker : {}

      fields.each do |field, value|
        key = Key.parse field
        tracker.delete key.name

        add_missing(missing_params, key) if key_missing?(params, key)
        next if params[key.name].nil?

        if Class === value
          type_mismatches << key.name unless params[key.name].is_a?(value)
        elsif value.is_a?(Array) && value.size <= 1
          if !params[key.name].is_a?(Array)
            type_mismatches << key.name
          elsif value[0] && !all_correct_types?(params[key.name], value[0])
            type_mismatches << key.name
          end
        elsif Hash === value
          tmp_missing_params, tmp_unpermitted_params, tmp_type_mismatches = lint_hash(params[key.name], value)

          missing_params << {key.name => tmp_missing_params} if !tmp_missing_params.empty?
          unpermitted_params << {key.name => tmp_unpermitted_params} if !tmp_unpermitted_params.empty?
          type_mismatches << {key.name => tmp_type_mismatches} if !tmp_type_mismatches.empty?
        else
          raise "bad value: #{value.inspect}"
        end
      end
      unpermitted_params.concat tracker.keys
      unpermitted_params -= %w(format action controller)
      [missing_params, unpermitted_params, type_mismatches]
    end

    def all_correct_types?(values, klass)
      values.all? {|value| value.is_a?(klass) }
    end

    def key_missing?(params, key)
      key.required? && !params.has_key?(key.name)
    end

    def add_missing(missing_params, key)
      missing_params << key.name
    end

    def formatted_headers(headers)
      headers.map do |key, value|
        "#{key}: #{value}"
      end
    end

    def verify!
      @missing_request_params, @unpermitted_request_params, @request_type_mismatches =
        lint_hash(sample_request_params, request_params)
      @missing_response_params, @unpermitted_response_params, @response_type_mismatches =
        lint_hash(sample_response_params, response_params)
    end
  end
end
