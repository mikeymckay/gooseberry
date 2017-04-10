configure do

  set :port, 9393

  puts "STARTING"
  $message_queue = []
  QUEUE_SHIFT_AMOUNT = 10
  LOAD_THRESHOLD = 2
  # Use a random sleep time to make sure the threads in other processes don't wake at the same time
  SECONDS_OF_SLEEP_BETWEEN_PROCESSING = 30 + rand(30)

  Thread.new {
    begin
      loop do
        sleep(SECONDS_OF_SLEEP_BETWEEN_PROCESSING)
        process_queue(nil)
      end
    rescue Exception => e
      puts "EXCEPTION: #{e.inspect}"
      puts "MESSAGE: #{e.message}"
    end
  }

end

def process_queue(params)
  def send_queued_message
    text = params["text"] || params["message"]
    message = "Thanks for your request to #{text}. We are currently receiving many messages and will respond to your request soon. You don't need to do anything else."
    return "web:#{message}" if params["from"] == 'web'
    # The number to which the message was sent
    $gateways[params["to"] || params["dest"]].send_message(
      params["from"] || params["org"],
      message,
      {
        "linkId" => params["linkId"],
        "bulkSMSMode" => 0
      }
    )
  end

  load_average = File.read("/proc/loadavg")[0..2].to_f
  puts "Processing queue, current load: #{load_average}, size: #{$message_queue.length}" if $message_queue.length > 1

  if load_average > LOAD_THRESHOLD
    send_queued_message if params
  else
    messages_to_process = $message_queue.shift(QUEUE_SHIFT_AMOUNT)
    return if messages_to_process.length == 0
    last_result = nil
    messages_to_process.each do |message_params|
      message = Message.new(message_params)
      last_result = message.process
    end
    puts "#{messages_to_process.length} START messages processed."

    if $message_queue.length > 0
      send_queued_message if params
      puts "#{$message_queue.len  gth} messages in the START message queue"
      return "Message queued"
    else
      return last_result.to_s
    end
  end

end

def incoming(params)
  puts "#{Time.now} Received: #{params}"

  text = params["text"] || params["message"]
  if text.match(/^Start (.+)/i)
    $message_queue.push(params)
    return process_queue(params)
  else
    message = Message.new(params)
    result = message.process
    return result.to_s
  end
end

get "/" do
  redirect $passwords_and_config["login_url"]
end

get "/incoming" do
  incoming(params)
end

get "/:phone_number/incoming" do
  incoming(params)
end

post "/:phone_number/incoming" do
  incoming(params)
end

get "/send_reminders/:question_set/:minutes" do |question_set_name,minutes|
  question_set= $db.get question_set_name

  result = ""

  $db.view("reminders/reminders", {
    "startkey" => [question_set_name],
    "endkey" => [question_set_name,{}],
    "include_docs" => true
  })['rows'].each{|row|
    from = row["key"][1]
    puts row["value"].inspect
    reminders = row["value"][0] || []
    updated_at = DateTime.parse row["value"][1]

    minutes_since_last_update = ((DateTime.now - updated_at) * 24 * 60).to_i

    if reminders.length < 2 and minutes_since_last_update > minutes.to_i

      outstanding_question = question_set["questions"][row["doc"]["current_question_index"]]["text"]
      linkId = row["doc"]["linkId"]

      message = "REMINDER: #{outstanding_question}"
      puts "Sending #{from}: #{message}"
      result += "Sending #{from}: #{message}<br/>"

      if linkId #source was an SMS
        result = $gateway.send_message(
          from,
          message,
          {
            "linkId" => linkId,
            "bulkSMSMode" => 0
          }
        )
        doc = row["doc"]
        doc["updated_at"] = Time.now.to_s
        doc["time_reminders_sent"] = [] unless doc["time_reminders_sent"]
        doc["time_reminders_sent"].push Time.now.to_s
        $db.save_doc doc

      else # source was via web
        puts "Not sending reminder to #{from} since it was entered via the web"
        result += "Not sending reminder to #{from} since it was entered via the web<br/>"
      end

    end
  }
  result

end
