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


require_relative  'AfricasTalkingGateway'

$passwords_and_config = JSON.parse(IO.read("passwords_and_config.json"))
$gateway = AfricasTalkingGateway.new($passwords_and_config["username"],$passwords_and_config["api_key"])

require_relative  'methods'
require_relative  'routes'
