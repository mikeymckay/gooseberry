require 'rubygems'
require 'curb'
require 'json'

class AfricasTalkingGatewayError < Exception
end

class SMSMessage
  attr_accessor :id, :text, :from, :to, :linkId, :date

  def initialize(m_id, m_text, m_from, m_to, m_linkId, m_date)
    @id = m_id
    @text = m_text
    @from = m_from
    @to = m_to
    @linkId = m_linkId
    @date = m_date
  end
end

class StatusReport
  attr_accessor :number, :status, :cost

  def initialize(m_number, m_status, m_cost)
    @number = m_number
    @status = m_status
    @cost = m_cost
  end
end

class AfricasTalkingGateway

  SMS_URL     = 'https://api.africastalking.com/version1/messaging'
  VOICE_URL   = 'https://voice.africastalking.com/call'
  ACCEPT_TYPE = 'application/json'

  def initialize(user_name,api_key)
    @user_name = user_name
    @api_key = api_key
  end

  def send_message(recipients, message)
    data = nil
    response_code = nil

    post_body = {:username => @user_name, :message => message, :to => recipients }

    http = Curl.post(SMS_URL, post_body) do |curl|
      curl.headers['Accept'] = ACCEPT_TYPE
      curl.headers['apiKey'] = @api_key
      curl.on_body { |body|
        data = body
        body.to_s.length
      }
      curl.on_complete { |resp| response_code = resp.response_code }
    end

    if response_code == 201
      reports = JSON.parse(data)["SMSMessageData"]["Recipients"].collect { |entry|
        StatusReport.new entry["number"], entry["status"], entry["cost"]
      }
      return reports
    else
      raise AfricasTalkingGatewayError, JSON.parse(data)["SMSMessageData"]["Message"]
    end
  end

  def call(from, to)
    data          = nil
    response_code = nil

    post_body = {:username => @user_name, :from => from, :to => to }

    http = Curl.post(VOICE_URL, post_body) do |curl|
      curl.headers['Accept'] = ACCEPT_TYPE
      curl.headers['apiKey'] = @api_key

      curl.on_body { |body|
        data = body
        body.to_s.length
      }
      curl.on_complete { |resp| response_code = resp.response_code }
    end

    raise AfricasTalkingGatewayError, JSON.parse(data)["ErrorMessage"] if response_code != 201

  end

  def fetch_messages(last_received_id)
    data = nil
    response_code = nil

    http = Curl.get("#{SMS_URL}?username=#{@user_name}&lastReceivedId=#{last_received_id}") do |curl|
      curl.headers['Accept'] = ACCEPT_TYPE
      curl.headers['apiKey'] = @api_key
      curl.on_body { |body|
        data = body
        body.to_s.length
      }
      curl.on_complete { |resp| response_code = resp.response_code }
    end

    if response_code == 200
      messages = JSON.parse(data)["SMSMessageData"]["Messages"].collect { |msg|
        SMSMessage.new msg["id"], msg["text"], msg["from"] , msg["to"], msg["linkId"], msg["date"]
      }
      return messages
    end

    raise AfricasTalkingGatewayError, JSON.parse(data)["SMSMessageData"]["Message"]

  end
end
