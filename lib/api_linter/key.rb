module APILinter
  class Key
    attr_reader :name

    def self.parse(field)
      field = field.to_s
      results = field.match(/([^!]+)(!)?$/)

      if results[1][-1] == '\\' && results[2]
        name = results[1][0...-1] + '!'
        required = false
      else
        name = results[1]
        required = !results[2].nil?
      end

      new field, name, required
    end

    def initialize(field, name, required)
      @field = field
      @name = name
      @required = required
    end

    def required?
      @required
    end

    def extended_name
      name + (required? ? ' (required)' : '')
    end
  end
end
