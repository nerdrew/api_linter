require 'spec_helper'

describe APILinter::Key do
  describe '#name' do
    it 'returns the name' do
      described_class.parse('bam!').name.should == 'bam'
    end

    it 'returns the name with ! if escaped' do
      described_class.parse('bam\!').name.should == 'bam!'
    end
  end

  describe '#required?' do
    it 'returns true if the field is required' do
      described_class.parse('bam!').required?.should == true
    end

    it 'returns false if it is not required' do
      described_class.parse('bam\!').required?.should == false
    end
  end

  describe '#extended_name' do
    it 'returns the name with (required) if required' do
      described_class.parse('bam!').extended_name.should == 'bam (required)'
    end

    it 'returns the name if not required' do
      described_class.parse('bam').extended_name.should == 'bam'
    end
  end
end
