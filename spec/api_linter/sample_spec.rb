require 'spec_helper'
require 'api_linter/sample'

describe APILinter::Sample do
  describe '#results' do
    let(:sample) { APILinter::Sample.new({}) }

    it 'returns a formatted string with the request / response problems' do
      sample.stub(:missing_request_params) { 'missing request' }
      sample.stub(:missing_response_params) { 'missing response' }
      sample.stub(:unpermitted_request_params) { 'unpermitted request' }
      sample.stub(:unpermitted_response_params) { 'unpermitted response' }
      sample.stub(:request_type_mismatches) { 'bad request type' }
      sample.stub(:response_type_mismatches) { 'bad response type' }

      sample.results.should == <<-RESULTS.gsub(/^ {8}/, '')
        Missing request params: missing request
        Unpermitted request params: unpermitted request
        Request type mismatches: bad request type

        Missing response params: missing response
        Unpermitted response params: unpermitted response
        Request type mismatches: bad response type
      RESULTS
    end
  end

  describe '#request_passed?' do
    it 'returns true if there are no missing, unpermitted, or type mismatches' do
      APILinter::Sample.new({}).request_passed?.should == true
    end

    it 'returns false if there is >= 1 missing, unpermitted, or type mismatches' do
      APILinter::Sample.new(
        sample_request_params: {},
        request_params: {foo!: String}
      ).request_passed?.should == false
    end
  end

  describe '#response_passed?' do
    it 'returns true if there are no missing, unpermitted, or type mismatches' do
      APILinter::Sample.new({}).response_passed?.should == true
    end

    it 'returns false if there is >= 1 missing, unpermitted, or type mismatches' do
      APILinter::Sample.new(
        sample_response_params: {},
        response_params: {foo!: String}
      ).response_passed?.should == false
    end
  end

  describe 'missing request params' do
    it 'returns [] if nothing is required' do
      APILinter::Sample.new(
        sample_request_params: {},
        request_params: {bar: String}
      ).missing_request_params.should == []
    end

    it 'returns required missing request params' do
      APILinter::Sample.new(
        sample_request_params: {},
        request_params: {bar!: String}
      ).missing_request_params.should == ['bar']
    end

    it 'returns the required missing nested params' do
      APILinter::Sample.new(
        sample_request_params: {bar: 1}.with_indifferent_access,
        request_params: {bar!: {goat!: String}}
      ).missing_request_params.should == [{"bar" => ["goat"]}]
    end
  end

  describe 'missing response params' do
    it 'returns [] if nothing is required' do
      APILinter::Sample.new(
        sample_response_params: {},
        response_params: {bar: String}
      ).missing_response_params.should == []
    end

    it 'returns required missing response params' do
      APILinter::Sample.new(
        sample_response_params: {},
        response_params: {bar!: String}
      ).missing_response_params.should == ['bar']
    end

    it 'returns the required missing nested params' do
      APILinter::Sample.new(
        sample_response_params: {bar: 1}.with_indifferent_access,
        response_params: {bar!: {goat!: String}}
      ).missing_response_params.should == [{"bar" => ["goat"]}]
    end
  end

  describe 'unpermitted request params' do
    it 'returns [] if everything is permitted' do
      APILinter::Sample.new(
        sample_request_params: {bam: 2}.with_indifferent_access,
        request_params: {bam: String}
      ).unpermitted_request_params.should == []
    end

    it 'returns unpermitted fields' do
      APILinter::Sample.new(
        sample_request_params: {bam: 2, horse: 3}.with_indifferent_access,
        request_params: {bam: String, house: Integer}
      ).unpermitted_request_params.should == ['horse']
    end

    it 'returns unpermitted nested fields' do
      APILinter::Sample.new(
        sample_request_params: {bam: {goat: 1, dog: 2}}.with_indifferent_access,
        request_params: {bam: {goat: Integer}}
      ).unpermitted_request_params.should =~ [{'bam' => ['dog']}]
    end
  end

  describe 'unpermitted response params' do
    it 'returns [] if everything is permitted' do
      APILinter::Sample.new(
        sample_response_params: {bam: 2}.with_indifferent_access,
        response_params: {bam: String}
      ).unpermitted_response_params.should == []
    end

    it 'returns unpermitted fields' do
      APILinter::Sample.new(
        sample_response_params: {bam: 2, horse: 3}.with_indifferent_access,
        response_params: {bam: String, house: Integer}
      ).unpermitted_response_params.should == ['horse']
    end

    it 'returns unpermitted nested fields' do
      APILinter::Sample.new(
        sample_response_params: {bam: {goat: 1, dog: 2}}.with_indifferent_access,
        response_params: { bam: {goat: Integer}}
      ).unpermitted_response_params.should =~ [{'bam' => ['dog']}]
    end
  end

  describe 'request type mismatches' do
    it 'does not check missing keys' do
      APILinter::Sample.new(
        sample_request_params: {bam: 2}.with_indifferent_access,
        request_params: {bam: String, horse: Integer}
      ).request_type_mismatches.should == ['bam']
    end

    it 'returns [] if all the types match' do
      APILinter::Sample.new(
        sample_request_params: {bam: 2}.with_indifferent_access,
        request_params: {bam: Integer}
      ).request_type_mismatches.should == []
    end

    it 'returns fields whose type does not match' do
      APILinter::Sample.new(
        sample_request_params: {bam: 2, horse: 3}.with_indifferent_access,
        request_params: {bam: String, horse: Integer}
      ).request_type_mismatches.should == ['bam']
    end

    it 'returns nested fields whose type does not match' do
      APILinter::Sample.new(
        sample_request_params: {bam: {goat: 1, dog: 2}}.with_indifferent_access,
        request_params: {bam: {goat: Integer, dog: String}}
      ).request_type_mismatches.should == [{'bam' => ['dog']}]
    end

    it 'returns fields whose array of type does not match' do
      APILinter::Sample.new(
        sample_request_params: {bam: ['hey']}.with_indifferent_access,
        request_params: {bam: [Integer]}
      ).request_type_mismatches.should == ['bam']
    end
  end

  describe 'response type mismatches' do
    it 'does not check missing keys' do
      APILinter::Sample.new(
        sample_response_params: {bam: 2}.with_indifferent_access,
        response_params: {bam: String, horse: Integer}
      ).response_type_mismatches.should == ['bam']
    end

    it 'returns [] if all the types match' do
      APILinter::Sample.new(
        sample_response_params: {bam: 2}.with_indifferent_access,
        response_params: {bam: Integer}
      ).response_type_mismatches.should == []
    end

    it 'returns fields whose type does not match' do
      APILinter::Sample.new(
        sample_response_params: {bam: 2, horse: 3}.with_indifferent_access,
        response_params: {bam: String, horse: Integer}
      ).response_type_mismatches.should == ['bam']
    end

    it 'returns nested fields whose type does not match' do
      APILinter::Sample.new(
        sample_response_params: {bam: {goat: 1, dog: 2}}.with_indifferent_access,
        response_params: {bam: {goat: Integer, dog: String}}
      ).response_type_mismatches.should == [{'bam' => ['dog']}]
    end

    it 'returns fields whose array of type does not match' do
      APILinter::Sample.new(
        sample_response_params: {bam: ['hey']}.with_indifferent_access,
        response_params: {bam: [Integer]}
      ).response_type_mismatches.should == ['bam']
    end
  end

  describe '#document' do
    let(:sample) do
      APILinter::Sample.new(
        sample_request_params: {boo: 'ghost'},
        sample_response_params: {hoot: 'nanny'},
        status: 200,
        sample_request_headers: {'Foo' => 'bar'},
        sample_response_headers: {'Cat' => 'dog'}
      )
    end

    it 'documents the sample' do
      sample.document('GET', '/bam?you=me', 'user', 'pass').should == <<-DOC.gsub(/^ {8}/, '')
        curl -i -H 'Content-Type: application/json' -H 'Foo: bar' -u 'user:pass' -X POST http://localhost:3000/bam?you=me -d '
        {
          "boo": "ghost"
        }
        '

        HTTP/1.1 200 OK
        Cat: dog

        {
          "hoot": "nanny"
        }
      DOC
    end
  end
end
