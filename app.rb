require 'rubygems'
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

configure do
  enable :cross_origin
end

#RestClient.log = 'stdout'

$passwords_and_config = JSON.parse(IO.read("passwords_and_config.json"))
$database_name = "gooseberry"
usernamePassword = $passwords_and_config['database_username']+":"+$passwords_and_config['database_password']
$db = CouchRest.database("http://#{usernamePassword}@localhost:5984/#{$database_name}")

require_relative 'AfricasTalkingGateway'

$gateway = AfricasTalkingGateway.new(
  $passwords_and_config["username"], 
  $passwords_and_config["api_key"],
  $passwords_and_config["phone_number"]
)

require_relative 'reports'
require_relative 'Message'
require_relative 'ValidationHelpers'
require_relative 'ZanzibarHelpers'
require_relative 'QuestionSets'
require_relative 'routes'
