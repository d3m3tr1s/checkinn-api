require File.join(File.dirname(__FILE__), '..', 'init.rb')

require 'rubygems'
require 'bundler'
require 'sinatra'
require 'rspec'
require 'rack/test'

# setup test environment
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

def app
  CheckinnApi
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
end