require 'spec_helper'
require 'api_linter/linter'

describe APILinter::Linter do
  before { APILinter::Linter.clear }

  describe '.register_linters' do
    it 'registers linters' do
      APILinter::Linter.register_linters 'GET /bam' => {
        request: {params: :req_params}, response: {params: :res_params}
      }
      APILinter::Linter.linters.size.should == 1
      APILinter::Linter.linters[0].route.should == '/bam'
      APILinter::Linter.linters[0].request_params.should == :req_params
      APILinter::Linter.linters[0].response_params.should == :res_params
    end
  end

  describe '.for_route' do
    it 'finds the linter matching the method AND route regex' do
      APILinter::Linter.register_linters('GET /bam' => {}, 'GET /foo/:id' => {})
      APILinter::Linter.for_route('GET', '/foo/1').should eq APILinter::Linter.linters[1]
    end

    it 'finds the linter matching the method AND route regex' do
      APILinter::Linter.register_linters('GET /bam' => {}, 'PUT /bam' => {})
      APILinter::Linter.for_route('PUT', '/bam').should eq APILinter::Linter.linters[1]
    end
  end

  describe '.document' do
    it 'returns a header and the documentation for each linter' do
      APILinter::Linter.register_linters('GET /bam/:id' => {})
      APILinter::Linter.any_instance.stub(:document) { 'Linter 0 Documentation' }
      APILinter::Linter.document.should == "# API\n\nLinter 0 Documentation"
    end
  end

  # TODO .results spec

  describe '#route_regex' do
    it 'returns a regex built from the route' do
      APILinter::Linter.new('GET /bam/:foo/hard', {}).route_regex.
        should == %r{/bam/[^/]+/hard}
    end
  end

  describe '#check' do
    let(:request_params) { double :request_params }
    let(:response_params) { double :response_params }
    let(:linter) do
      APILinter::Linter.new 'GET /bam/:foo/hard',
        request: {params: request_params},
        response: {params: response_params}
    end

    it 'creates a new APILinter::Sample' do
      APILinter::Sample.should_receive(:new).with(
        request_params: request_params,
        response_params: response_params
      )
      linter.check({})
    end
  end

  describe '#document' do
    subject do
      APILinter::Linter.new 'GET /foo', {
        title: 'Title',
        description: 'Blurb',
        request: {params: {foo: String}},
        response: {params: {bar!: Integer}}
      }
    end

    before do
      subject.stub(:samples) { [double(:sample, document: 'sample 1')] }
    end

    its(:document) do
      should == <<-DOC.gsub(/^ {8}/, '')
        ## Title: GET /foo

        Blurb

        ### Request

        #### Body
        ```json
        {
          "foo": "String"
        }
        ```

        ### Response

        #### Body
        ```json
        {
          "bar (required)": "Integer"
        }
        ```

        Examples:
        ```
        sample 1
        ```
      DOC
    end
  end
end
