if defined? RSpec
  RSpec.configure do |config|
    config.treat_symbols_as_metadata_keys_with_true_values = true

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

    config.after(:all) do
      puts "\n\n"
      puts "Documentation written to: doc/README.md"
      documentation.rewind
      puts documentation.read
      lint_output.rewind
      puts lint_output.read
    end
  end
end
