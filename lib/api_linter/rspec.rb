require 'api_linter/linter'
require 'api_linter/lint_middleware'

module APILinter
  module Config
    class <<self
      attr_writer :output, :documentation, :lint_output, :strict
      attr_reader :description
      attr_accessor :username, :password
    end

    def self.output
      @output ||= $stdout
    end

    def self.lint_output
      @lint_output || output
    end

    def self.documentation
      @documentation || output
    end

    def self.strict?
      @strict == true
    end

    def self.document(description = nil)
      @description = description
      @document = true
      yield
    ensure
      @document = false
      @description = nil
    end

    def self.document?
      @document == true
    end
  end
end

if defined? RSpec
  RSpec.configure do |config|
    config.treat_symbols_as_metadata_keys_with_true_values = true

    # TODO do the output streams need to be configurable?
    documentation = StringIO.new
    lint_output = StringIO.new

    APILinter::Config.documentation = documentation
    APILinter::Config.lint_output = lint_output

    config.around(:each) do |example|
      if description = example.metadata[:document_api]
        description = description.is_a?(String) ? description : nil

        APILinter::Config.document description do
          example.call
        end
      end
    end

    # TODO instead of configurable output streams, just write everything to doc/<file>
    # TODO put each route into it's own file?
    config.after(:all) do
      puts "\n\n"
      puts "Documentation written to: doc/README.md"
      documentation.write APILinter::Linter.document
      documentation.rewind
      puts documentation.read
      lint_output.write APILinter::Linter.results
      lint_output.rewind
      puts lint_output.read
    end
  end
end
