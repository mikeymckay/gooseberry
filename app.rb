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
require 'lru_redux' # least recently used cache for duplicate incoming messages

configure do
  enable :cross_origin
end

#RestClient.log = 'stdout'

$passwords_and_config = JSON.parse(IO.read("passwords_and_config.json"))
$db = CouchRest.database($passwords_and_config['database_url'])
$db_log = CouchRest.database("#{$passwords_and_config['database_url']}-log")

require_relative 'AfricasTalkingGateway'

$gateway = AfricasTalkingGateway.new(
  $passwords_and_config["username"], 
  $passwords_and_config["api_key"],
  $passwords_and_config["phone_number"]
)

# Keep last 10000 messages sent in a cache to check for incoming duplicates
# See incoming in routes.rb
$incomingMessageLRUCache = LruRedux::Cache.new(10000)

require_relative 'reports'
require_relative 'Message'
require_relative 'ValidationHelpers'
require_relative 'ZanzibarHelpers'
require_relative 'QuestionSets'
require_relative 'routes'
require_relative 'file_upload'
