require 'rubygems'
require 'bundler'
Bundler.setup(:default)

require 'sinatra'
require 'api_linter'

APILinter::Config.output = StringIO.new
use APILinter::LintMiddleware, {'GET /hello/:name/goodbye' => {
  request: {params: {cat: String, mouse!: Integer}},
  response: {params: {house!: String}}
}}

get '/hello/:slug/goodbye' do
  [200, {'Content-Type' => 'application/json'}, {house: 'sweet home', horse: 'barn'}.to_json]
end
