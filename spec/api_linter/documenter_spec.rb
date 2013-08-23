require 'spec_helper'

describe APILinter::Documenter do
  describe '#api_documentation' do
    subject { APILinter::Documenter.new method: 'GET', route: '/foo', title: 'Title', description: 'Blurb' }
    before do
      subject.stub(:request_documentation) { 'request_documentation' }
      subject.stub(:response_documentation) { 'response_documentation' }
      subject.stub(:formatted_request_headers) { ['formatted_request_headers'] }
      subject.stub(:formatted_response_headers) { ['formatted_response_headers'] }
      subject.stub(:sample) { 'curl sample' }
    end

    its(:api_documentation) do
      should == <<-DOC.gsub(/^ {8}/, '').chomp
        ## Title: GET /foo

        Blurb

        ### Request

        #### Headers
        formatted_request_headers

        #### Body
        ```json
        request_documentation
        ```

        ### Response

        #### Headers
        formatted_response_headers

        #### Body
        ```json
        response_documentation
        ```

        Example:
        ```
        curl sample
        ```
      DOC
    end
  end

  describe '#request_documentation' do
    subject { APILinter::Documenter.new(request_params: {bam!: {goat: [Integer], dog!: String}}) }
    its(:request_documentation) do
      should == <<-DOC.gsub(/^ {8}/, '').chomp
        {
          "bam (required)": {
            "goat": "Array of Integers",
            "dog (required)": "String"
          }
        }
      DOC
    end
  end

  describe '#response_documentation' do
    subject { APILinter::Documenter.new(response_params: {bam!: {goat: [Integer], dog!: String}}) }
    its(:response_documentation) do
      should == <<-DOC.gsub(/^ {8}/, '').chomp
        {
          "bam (required)": {
            "goat": "Array of Integers",
            "dog (required)": "String"
          }
        }
      DOC
    end
  end

  describe '#sample' do
    subject do
      APILinter::Documenter.new(
        sample_request_params: {boo: 'ghost'},
        method: 'POST',
        route: '/bam?you=me',
        sample_response_params: {hoot: 'nanny'},
        status: 200,
        username: 'user',
        password: 'pass',
        request_headers: {'Foo' => 'bar'},
        response_headers: {'Cat' => 'dog'}
      )
    end

    its(:sample) do
      should == <<-DOC.gsub(/^ {8}/, '').chomp
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

  describe '#formatted_request_headers' do
    subject { APILinter::Documenter.new(request_headers: {'Foo' => 'bam', 'Bar' => 'goat'}) }
    its(:formatted_request_headers) do
      should == ['Foo: bam', 'Bar: goat']
    end
  end

  describe '#formatted_response_headers' do
    subject { APILinter::Documenter.new(response_headers: {'Foo' => 'bam', 'Bar' => 'goat'}) }
    its(:formatted_response_headers) do
      should == ['Foo: bam', 'Bar: goat']
    end
  end
end

