
get '/' do

  question_sets_string =  QuestionSets.all.map do |question_set|
    "
      <li>
        #{question_set} <br/>
        <a href='' onClick='document.location = \"/#{$passwords_and_config["phone_number"]}/incoming?from=\"+ document.getElementsByTagName(\"input\")[0].value + \"&text=Start%20#{question_set}\";return false'>capture data</a> as <input value='web'></input><br/>
        <a href='/edit/#{question_set}'>edit questions</a> <br/>
        <a href='/table/#{question_set}'>results</a></li>
        <a href='/csv/#{question_set}'>csv</a></li>
    "
  end.join("")

  "
    <h1>Question Sets</h1>
   #{question_sets_string}

  "
end

get '/edit/:question_set' do |question_set|
  question_set = QuestionSets.get_question_set(question_set)
  "
<!DOCTYPE html>
<html lang='en'>
<head>
  <meta charset='UTF-8'>
  <meta http-equiv='X-UA-Compatible' content='IE=edge,chrome=1'>
  <title>Editor</title>
  <style type='text/css' media='screen'>
    body {
        overflow: hidden;
    }
    #editor {
        margin: 0;
        position: absolute;
        top: 100px;
        bottom: 0;
        left: 0;
        right: 0;
    }
  </style>
</head>
<body>

<button type='button' onClick='save()'>Save</button>
<a href='/'>Home</a>

<pre id='editor'>
}</pre>


<script src='/js/ace/ace.js' type='text/javascript' charset='utf-8'></script>
<script src='/js/jquery-2.1.0.min.js' type='text/javascript'></script>
<script>
    var editor = ace.edit('editor');
    editor.setTheme('ace/theme/twilight');
    editor.getSession().setMode('ace/mode/json');
    json = #{question_set.to_json}
    editor.setValue(JSON.stringify(json,null,2))
    save = function(){
      $.ajax(
        '#{$passwords_and_config["database_url"]}/#{question_set["_id"]}',{
          'contentType': 'application/json',
          'data': editor.getValue(),
          'type': 'PUT',
          'success': function(){document.location = '/'}
        }
      )
    }
</script>

</body>
</html>

  "

end

get '/csv/:question_set' do |question_set|
  content_type 'application/csv'
  attachment "#{question_set}-#{Time.now.strftime('%d-%m-%y--%H-%M')}.csv"
  get_csv(question_set)
end

get '/table/:question_set' do |question_set|
  table = get_table(question_set)
  "
  <html>
    <body>
      <a href='/'>Home</a>
      <br/>
      #{table}
    </body>
  </html>

  "
end

def incoming(params)
  puts "#{Time.now} Received: #{params}"
  message = Message.new(params)
  result = message.process

  puts result

  return "
    <h1>#{result}</h1>
    SMS:<br/> 
    <textarea style='height:200px;width:300px;'></textarea>
    <button type='button' onClick='document.location=document.location.href.replace(/text=.*/,\"text=\" + document.getElementsByTagName(\"textarea\")[0].value)'>Send</button>
    <br/>
    <br/>
    <br/>
    <a href='/'>Home</a>
  "
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

  $db.view("#{$database_name}/reminders", {
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
