require 'active_support/core_ext/object/deep_dup'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/core_ext/hash/indifferent_access'
require 'rails'
require "api_linter/version"
require 'api_linter/key'
require 'api_linter/sample'
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
