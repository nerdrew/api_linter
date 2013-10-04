module APILinter
  class Linter
    def self.clear
      @linters = []
    end

    def self.register_linters(new_linters)
      linters.concat new_linters.map {|route, options| new(route, options) }
    end

    def self.linters
      @linters ||= []
    end

    def self.for_route(method, route)
      linters.detect {|linter| method == linter.method && route =~ linter.route_regex}
    end

    def self.document
      <<-DOC.gsub(/^ {8}/, '').chomp
        # API

        #{linters.sort{|a,b| a.route <=> b.route }.map(&:document).join "\n\n"}
      DOC
    end

    # TODO how do we want to lint auth and headers?
    def initialize(route, options)
      @method, @route = route.split ' ', 2
      @title = options[:title]
      @description = options[:description]
      if options[:request]
        @request_params = options[:request][:params]
      end
      if options[:response]
        @response_params = options[:response][:params]
        @allowed_statuses = options[:response][:allowed_statuses]
      end
      @samples = []
    end

    attr_reader :route, :request_params, :response_params, :allowed_statuses, :method,
      :request_headers, :response_headers, :title, :description, :samples

    def route_regex
      @regex ||= Regexp.new @route.gsub(/:[^\/]+/, '[^/]+')
    end

    def check(options = {})
      @samples << Sample.new(options.merge(
        request_params: request_params,
        response_params: response_params
      ))
    end

    def document
      description = "\n#{self.description}\n" if self.description
      if self.title
        title = "#{self.title}: #{method} #{route}"
      else
        title = "#{method} #{route}"
      end

      @@template ||= begin
        template_file = File.join(File.expand_path('..', __FILE__), 'templates', 'linter.md.erb')
        ERB.new File.read template_file
      end
      @@template.result binding
    end

    private

    def document_samples
      samples.map do |sample|
        sample.document method, route
      end.join "\n\n"
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
