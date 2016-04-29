
def incoming(params)
  puts "#{Time.now} Received: #{params}"
  message = Message.new(params)
  result = message.process

  return result
end

get "/" do
  redirect $passwords_and_config["login_url"]
end

get "/incoming" do
  incoming(params)
end

get "/#{$passwords_and_config["phone_number"]}/incoming" do
  incoming(params)
end

post "/#{$passwords_and_config["phone_number"]}/incoming" do
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
