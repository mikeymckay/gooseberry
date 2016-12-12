require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'couchrest'
require 'rest-client'
require 'cgi'
require 'json'
require 'net/http'
require 'yaml'
require 'csv'
require 'securerandom'
require 'date'
require 'time'
require 'fuzzy_match'
require 'sinatra/cross_origin'
require 'active_support/inflector'
#require 'profiler'

configure do
  enable :cross_origin
end

RestClient.log = 'stdout'

$passwords_and_config = JSON.parse(IO.read("passwords_and_config.json"))
$db = CouchRest.database($passwords_and_config['database_url'])
$db_log = CouchRest.database("#{$passwords_and_config['database_url']}-log")

require_relative 'AfricasTalkingGateway'

$gateways = {}
$passwords_and_config["gateways"].each do |gateway|
  $gateways[gateway["phone_number"]] = AfricasTalkingGateway.new(
    gateway["username"], 
    gateway["api_key"],
    gateway["phone_number"]
  )
end

require_relative 'reports'
require_relative 'Message'
require_relative 'ValidationHelpers'
require_relative 'ZanzibarHelpers'
require_relative 'QuestionSets'
require_relative 'routes'
require_relative 'file_upload'
require_relative 'ReuseDataHelpers'
