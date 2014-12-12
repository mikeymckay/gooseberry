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

$passwords_and_config = JSON.parse(IO.read("passwords_and_config.json"))
$database_name = "gooseberry"
$db = CouchRest.database("http://localhost:5984/#{$database_name}")

require_relative 'AfricasTalkingGateway'

$gateway = AfricasTalkingGateway.new(
  $passwords_and_config["username"], 
  $passwords_and_config["api_key"],
  $passwords_and_config["phone_number"]
)

require_relative 'reports'
require_relative 'Message'
require_relative 'ValidationHelpers'
require_relative 'QuestionSets'
require_relative 'routes'
