require 'spec_helper'

RSpec.describe APILinter::Lint do
  linter = Class.new { include APILinter::Lint }.new

  describe '#lint' do
    it 'does not raise if there are no missing, unpermitted, or type mismatches' do
      expect { linter.lint({'foo' => 2, 'boo' => 'goat'}, {foo!: Integer, boo: String}) }
          .not_to raise_exception
    end

    it 'raises if there is a missing required param' do
      expect { linter.lint({}, {foo!: String}) }
          .to raise_exception(APILinter::Error)
    end

    it 'raises if there is an unpermitted param' do
      expect { linter.lint({'bam' => 'Horse'}, {foo: String}) }
          .to raise_exception(APILinter::Error)
    end

    it 'raises if there is a type mismatch' do
      expect { linter.lint({'foo' => 'Horse'}, {foo: Integer}) }
          .to raise_exception(APILinter::Error)
    end
  end
end
