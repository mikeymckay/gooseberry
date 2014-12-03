
get '/' do

  question_sets_string =  question_sets().map do |question_set|
    "
      <li>
        #{question_set} <br/>
        <a href='' onClick='document.location = \"/#{$passwords_and_config["phone_number"]}/incoming?from=\"+ document.getElementsByTagName(\"input\")[0].value + \"&text=Start%20#{question_set}\";return false'>capture data</a> as <input value='web'></input><br/>
        <a href='/edit/#{question_set}'>edit questions</a> <br/>
        <a href='/csv/#{question_set}'>csv</a></li>
    "
  end.join("")

  "
    <h1>Question Sets</h1>
   #{question_sets_string}

  "
end

get '/edit/:question_set' do |question_set|
  question_set = get_question_set(question_set)
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


get "/#{$passwords_and_config["phone_number"]}/incoming" do

  from = params["from"] # The number that sent the message
  to = params["to"]     # The number to which the message was sent
  text = params["text"] # The message content
  date = params["date"] # The date and time when the message was received
  id = params["id"]     # The internal ID that we use to store this message
  linkId = params["linkId"] # Optional parameter required when responding to an on-demand user request with a premium message

  state = get_state(from, text)

  case text
    when /^Start (.+)/i
      state["question_set"] = $1
    when /^Reset$/i
      state["current_question_index"] = nil
      state["results"] = []
    else
      if state["question_set"].nil?
        send_message(from,"No question set loaded.")
        return
      end
  end

  questions = get_questions_for_question_set(state["question_set"])

  validation_message = nil
  current_question_index = -1

  if state["current_question_index"]
    current_question_index = state["current_question_index"]
    current_question = questions[current_question_index]

    answer = if current_question["post_process"]
      eval "answer = '#{text}';#{current_question["post_process"]}"
    else
      text
    end

    validation_message = if current_question["validation"]
      eval "answer = '#{answer}';#{current_question["validation"]}"
    end

    state["results"].push (
      {
        "question_index" => current_question_index,
        "question" => current_question["text"],
        "answer" => answer,
        "valid" => validation_message ? validation_message : true,
        "datetime" => Time.now.to_s
      }
    )

    # Redo the same question if it was invalid
    current_question_index = current_question_index-1 if validation_message
  end

  message = ""
  current_question_index += 1
  if questions[current_question_index]
    state["current_question_index"] = current_question_index
    message = questions[current_question_index]["text"]
    message = "#{validation_message}, try again: #{message}" if validation_message
  else
    state["current_question_index"] = nil
    message = "#{state["question_set"]} has been completed - thanks."
  end

  result = send_message(from,message)
  # TODO check result to make sure message was sent before saving state
  save_state(state)

  return "
    <h1>#{result}</h1>
    SMS:<br/> 
    <textarea style='height:200px;width:300px;'></textarea>
    <button type='button' onClick='document.location=document.location.href.replace(/text=.*/,\"text=\" + document.getElementsByTagName(\"textarea\")[0].value)'>Send</button>
    <br/>
    <br/>
    <br/>
    <a href='/#{$passwords_and_config["phone_number"]}/incoming?from=web&text=Start%20Nairobi%201'>Start Nairobi 1</a>
  "
end
