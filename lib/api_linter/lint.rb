require 'api_linter/key'

module APILinter
  class Error < StandardError
    def initialize(missing, unpermitted, mismatch)
      msg = []
      msg << "Missing params: #{missing.join(', ')}" unless missing.empty?
      msg << "Unpermitted params: #{unpermitted.join(', ')}" unless unpermitted.empty?
      msg << "Type mismatch params: #{mismatch.join(', ')}" unless mismatch.empty?
      super(msg.join('; '))
    end
  end

  module Lint
    def lint(params, fields)
      missing, unpermitted, mismatch = lint_hash(params, fields)
      fail Error.new(missing, unpermitted, mismatch) unless missing.empty? &&
        unpermitted.empty? && mismatch.empty?
    end

    private

    def lint_hash(params, fields, missing_params = [], unpermitted_params = [], tracker = nil, type_mismatches = [])
      params = params.is_a?(Hash) ? params : {}

      tracker ||= params.deep_dup
      tracker = tracker.is_a?(Hash) ? tracker : {}

      fields.each do |field, value|
        key = Key.parse field
        tracker.delete key.name

        missing_params << key.name if key_missing?(params, key)
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
  end
end
