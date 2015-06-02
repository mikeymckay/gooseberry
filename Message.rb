class Message

  def initialize(options)
    @from = options["from"] || options["org"]  # The number that sent the message
    @to = options["to"] || options["dest"] # The number to which the message was sent
    @date = options["date"] # The date and time when the message was received
    @id = options["id"]     # The internal ID that we use to store this message
    @linkId = options["linkId"] # Optional parameter required when responding to an on-demand user request with a premium message
    @text = if options["text"]
      clean options["text"]
    elsif options["message"]
      clean options["message"]
    end

    log_incoming_message()

  end

  def log_incoming_message
    $db_log.save_doc ({
      "type" => "incoming",
      "to" => @to,
      "from" => @from,
      "message" => @text,
      "time" => Time.now.strftime("%Y-%m-%d %H:%M:%S.%3N"),
      "id" => @id,
      "linkId" => @linkId
    })
  end

  def process
    set_most_recent_state
    return unless process_triggers
    set_questions
    process_answer
    result = send_next_message
    # TODO check result to make sure message was sent before saving state
    complete_action if complete?
    save_state
    return result
  end

  def complete_action
    complete_action_string = QuestionSets.get_question_set(@state["question_set"])["complete action"]
    if complete_action_string
      puts complete_action_string
      message = self
      eval complete_action_string
    end
  end

  def clean(text)
    if ! text.valid_encoding?
      text.encode!("US-ASCII", :invalid=>:replace, :replace=>"?").encode('US-ASCII')
    end
    # Replace all leading spaces
    # Replace two or more spaces with a single space
    text.gsub(/^ +/, '').gsub(/  +/, ' ')
  end

  def default_empty_state
    {
      "from" => @from,
      "linkId" => @linkId,
      "current_question_index" => nil,
      "complete" => false,
      "results" => [
      ]
    }
  end

  def states_for_user
    $db.view("#{$database_name}/states", {
      "key" => @from,
      "include_docs" => true
    })['rows']
  end

  def get_state_for_user_with_question_set(question_set)
    states_for_user.find{|state|state["question_set"] == question_set}
  end

  def set_most_recent_state
    states = states_for_user()

    if states.length == 0
      @state = default_empty_state
    else
      # Get the most recently updated state
      @state = states.max_by{|state|state["value"][1]}["doc"]
    end

  end

  def look_for_start_triggers
    result = true
    if @text.match(/ /) # configured trigger words don't have spaces
      # default trigger uses word start followed by question set id
      if @text.match(/^Start (.+)/i)
        result = process_start_triggers($1)
      end
    else
      # check for a match on configured trigger words
      first_matched_trigger_word = $db.view("#{$database_name}/trigger_words", {
        "key" => @text.upcase,
        "include_docs" => false
      })['rows'][0]

      if first_matched_trigger_word
        result = process_start_triggers(first_matched_trigger_word["value"])
      end
    end

    return false if result == false
  end

  def process_start_triggers(question_set_name)
    question_set = QuestionSets.get_question_set(question_set_name)
    if question_set.nil?
      closest_match = FuzzyMatch.new(QuestionSets.all).find(question_set_name)
      send_message(@from, "#{question_set_name} is not a valid question set - did you mean #{closest_match}? Please try again.") unless QuestionSets.get_question_set(question_set_name)
      return false
    else
      # If the question_set to start isn't the most recently used state, get the right one or create a new one
      if question_set_name != @state["question_set"]
        @state = get_state_for_user_with_question_set(question_set_name)
        if @state.nil?
          new_state(question_set_name)
        end
      # Else create a new state
      else
        new_state(question_set_name)
      end

      # Allows us to run some code to see if we should proceed
      # For example - only send if the number is known
      pre_run_requirement = question_set["pre_run_requirement"]
      if pre_run_requirement
        pre_run_requirement_message = eval pre_run_requirement
        puts pre_run_requirement_message
        if pre_run_requirement_message
          send_message(@from,pre_run_requirement_message)
          return false
        end
      end
    end

  end

  def process_triggers
    result = look_for_start_triggers
    return if result == false

    if @text.match(/^$/i)
      reset_state
    else
      if @state["question_set"].nil?
        puts "No question set loaded."
        return false
      elsif complete?
        puts "Question set complete - nothing left to do."
        return false
      end
    end
    true
  end

  def new_state(question_set_name)
    @state = default_empty_state
    @state["question_set"] = question_set_name
    @state["current_question_index"] = nil
  end

  def reset_state
    @state["current_question_index"] = nil
    @state["results"] = []
    @state["complete"] = false
  end

  def new_state?
    @state["current_question_index"].nil?
  end

  def process_answer
    @validation_message = nil
    @current_question_index = -1

    if not new_state?

      @current_question_index = @state["current_question_index"]
      current_question = @questions[@current_question_index]

      answer = @text
      if current_question["post_process"]
        answer = eval "answer = '#{@text.sub(/'/,'') if @text}';#{current_question["post_process"]}"
      end

      @validation_message = if current_question["validation"]
        eval "answer = '#{answer.sub(/'/,'') if answer}';#{current_question["validation"]}"
      end

      @state["results"].push(
        {
          "question_index" => @current_question_index,
          "question_name" => current_question["name"],
          "question" => current_question["text"],
          "answer" => answer,
          "valid" => @validation_message ? @validation_message : true,
          "datetime" => Time.now.to_s
        }
      )

      # Redo the same question if it was invalid
      @current_question_index = @current_question_index-1 if @validation_message
    end
  end

  def send_next_message
    message = ""
    @current_question_index += 1

    if @questions[@current_question_index]

      skip_if = @questions[@current_question_index]["skip_if"]
# Creates a hash called answers that enables you to insert previous results into the response
      if skip_if 
        answers_hash = {}
        @state["results"].each do |result|
          index = result["question_name"] || result["question"]
          answers_hash[index] = result["answer"]
        end
        if(eval "answers = #{answers_hash};#{skip_if}")
          return send_next_message() #RECURSE
        end
        answer["other_data"].each do |property,value|
          answer[property] = value
        end
        delete answer["other_data"]
      end

      puts answers

      @state["current_question_index"] = @current_question_index
      message = @questions[@current_question_index]["text"]
      message = eval "\"#{message}\"" # Allows you to dynamically change the text of the message
      message = "#{@validation_message} #{message}" if @validation_message
    else
      @state["current_question_index"] = nil
      # Check for a complete message, or just use the default
      complete_message = QuestionSets.get_question_set(@state["question_set"])["complete message"]

      message = if complete_message
        evaluate_complete_message(complete_message)
      else
        "#{@state["question_set"]} is complete - thanks."
      end

      @state["complete"] = true
    end

    send_message(@from,message)
  end

  def evaluate_complete_message(complete_message)
    # create a string with all of the results set as variables names so that it can be eval'd and the variables used
    sets_results_as_variables = @state["results"].find_all{|result|
      result["valid"] == true
    }.map{|result|
      if result["question_name"]
        "#{result["question_name"]} = \"#{result["answer"]}\""
      end
    }.compact.join(";")

    eval "#{sets_results_as_variables}; \"#{complete_message}\""
  end

  def add_data(data)
    @state["other_data"] = {} unless @state["other_data"]
    @state["other_data"].merge! data
    puts @state.inspect
    puts "----------------------"
  end

  def get_data(property)
    puts @state.inspect
    puts "***************"
    @state["other_data"][property] unless @state["other_data"].nil?
  end

  def save_state
    @state["updated_at"] = Time.now.to_s
    @state = $db.save_doc(@state)
  end

  def log_sent_message(to,message,response)
    $db_log.save_doc ({
      "type" => "sent",
      "to" => to,
      "from" => @from,
      "message" => message,
      "time" => Time.now.strftime("%Y-%m-%d %H:%M:%S.%3N"),
      "response" => response
    })
  end

  def send_message(to,message)

    response = nil
    if @from != "web"
      response = $gateway.send_message(
        to,
        message,
        {
          "linkId" => @linkId,
          "bulkSMSMode" => 0
        }
      )
    else # source was via web
      response = "#{to}:#{message}"
    end

    puts "Response from SMS Gateway: #{response}"
    log_sent_message(to,message,response)
    response

  end

  def set_questions
    @questions = QuestionSets.get_questions(@state["question_set"])
  end

  def complete?
    @state["complete"] == true
  end

  def from
    @from
  end

  def result_for_question_name(question_name)
    puts question_name
    @state["results"].find_all{|result|
      (result["text"] == question_name or result["question_name"] == question_name) and result["valid"] == true
      (result["text"] == question_name or result["question_name"] == question_name) and result["valid"] == true
    }.max_by{|result|
      result["datetime"]
    }["answer"]
  end


end

