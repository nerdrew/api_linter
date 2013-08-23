require_relative 'sinatra_app'
require 'rspec'
require 'rack/test'
require 'api_linter/rspec'

describe 'APILinter RSpec integration' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "documents the request", document_api: 'Hello Goodbye' do
    get '/hello/yes/goodbye?cat=linus'
    expect(last_response).to be_ok
    last_response.body.should == '{"house":"sweet home","horse":"barn"}'
  end

  it "does not document the request" do
    get '/hello/no/goodbye?dog=simon'
    expect(last_response).to be_ok
    last_response.body.should == '{"house":"sweet home","horse":"barn"}'
  end
end
