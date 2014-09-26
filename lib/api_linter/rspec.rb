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
