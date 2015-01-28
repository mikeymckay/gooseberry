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
$db = CouchRest.database("http://localhost:5984/#{$database_name}")

#require_relative 'AfricasTalkingGateway'
#$gateway = AfricasTalkingGateway.new(
#  $passwords_and_config["username"], 
#  $passwords_and_config["api_key"],
#  $passwords_and_config["phone_number"]
#)

class BongoLive
  def send_message(to,message, options)
    unless to[0] == "0" or to[0] == "+"
      to = "+" + to
    end
    puts "Send #{to}: #{message}."
    RestClient.get "http://www.bongolive.co.tz/api/sendSMS.php", {
      :params  => {
        :destnum    => to,
        :message    => message
      }.merge($passwords_and_config["bongo_credentials"])
    }
  end
end

$gateway = BongoLive.new()

require_relative 'reports'
require_relative 'Message'
require_relative 'ValidationHelpers'
require_relative 'ZanzibarHelpers'
require_relative 'QuestionSets'
require_relative 'routes'
require_relative 'routes_spreadsheet'
