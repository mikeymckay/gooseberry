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
    begin 
      set_most_recent_state
      return unless process_triggers
      set_questions
      process_answer
      result = send_next_message
      # TODO check result to make sure message was sent before saving state
      complete_action if complete?
      set_questions
      save_state
      return result
    rescue Exception => e
      "Error while processing:"
      puts e.to_yaml
      puts e.backtrace.inspect
    end
  end

  def complete_action
    complete_action_string = QuestionSets.get_question_set(@state["question_set"])["complete action"]
    if complete_action_string
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
    # Replace newlines with space
    # # Replace single quote and double quote with nothing
    text.gsub(/^ +/, '').gsub(/  +/, ' ').gsub(/\n/,' ').gsub(/"/,'').gsub(/'/,'')
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
    $db.view("states/states", {
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
        result = process_start_triggers($1.upcase)
      end
    else
      # check for a match on configured trigger words
      first_matched_trigger_word = $db.view("trigger_words/trigger_words", {
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
        if pre_run_requirement_message
          send_message(@from,pre_run_requirement_message)
          return false
        end
      end

      use_previous_results = question_set["use_previous_results"]
      if use_previous_results
        prev_results = relevant_previous_results
        if prev_results
          @previous_results = prev_results.map{ |question, answer|
            question = question.sub(/^\d+\/\d+ */,"") # remove 1/10  2/8 etc
            "#{question.humanize()}: #{answer}"
          }.join(", ")
        else
          @previous_results = nil
        end
      else
        @previous_results = nil
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

  def validation_message(validation_logic, answer)
    return (if validation_logic
      eval "#{values_for_interpolation};answer = '#{answer.gsub(/'/,'') if answer}';#{validation_logic}"
    end)
  end

  def process_answer
    @validation_message = nil
    @current_question_index = -1

    if not new_state?

      @current_question_index = @state["current_question_index"]
      current_question = @questions[@current_question_index]
      answer = @text

      #puts "current question: #{current_question["name"]}"
      #puts "answer = #{answer}"
      #puts "answer = '#{@text.gsub(/'/,'') if @text}';#{current_question["post_process"]}"

      if current_question["post_process"]
        answer = eval "answer = '#{@text.gsub(/'/,'') if @text}';#{current_question["post_process"]}"
      end

      @validation_message = validation_message(current_question["validation"], answer)

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
      # Ugly hack
      @current_question_index = -1 if @validation_message == "RESTARTING"
    end
  end

  def values_for_interpolation

    # create a string with all of the results in a hash so that it can be eval'd and the variables used
    # Also includes values from other_data
    string_to_eval = "result = {}; " + @state["results"].find_all{|result|
      result["valid"] == true
    }.map{|result|
      if result["question_name"]
        "result['#{result["question_name"]}'] = \"#{result["answer"]}\""
      end
    }.compact.join(";") + ";"

    # Legacy support requires us to also have the variables in a hash called answers
    string_to_eval += "result['from'] = '#{@from.gsub(/^254/,'0')}'; answers = result"

    string_to_eval
  end

  def send_next_message
    message = ""
    @current_question_index += 1

    if @questions[@current_question_index]

      if (@state["results"].find do |result|
        (result["question_name"] == @questions[@current_question_index]["name"] or result["question"] == @questions[@current_question_index]["text"]) and result["valid"] == true
      end)
        puts "Skipping #{@questions[@current_question_index]}"
        return send_next_message()
      end

      skip_if = @questions[@current_question_index]["skip_if"]
      # Creates a hash called answers that enables you to insert previous results into the response
      if skip_if 
        if eval("#{values_for_interpolation};#{skip_if}")
          return send_next_message() #RECURSE
        end
      end

      @state["current_question_index"] = @current_question_index
      message = @questions[@current_question_index]["text"]
      # Allows you to be able to refer to result["name_of_question"] in message
   
      message = eval "#{values_for_interpolation};\"#{message}\"" # Allows you to dynamically change the text of the message
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
    eval "#{values_for_interpolation}; \"#{complete_message}\""
  end

  def add_data(data)
    @state["other_data"] = {} unless @state["other_data"]
    @state["other_data"].merge! data
    #puts @state.inspect
    #puts "----------------------"
  end

  def get_data(property)
    #puts @state.inspect
    #puts "***************"
    @state["other_data"][property] unless @state["other_data"].nil?
  end

  def save_state
    @state["updated_at"] = Time.now.to_s
    begin
      @state = $db.save_doc(@state)
    rescue Exception => e
      STDERR.puts "Error saving #{@state}: #{e.message}"
    end
    return @state
  end

  def log_sent_message(to,message,response)
    puts ({
      "type" => "sent",
      "to" => to,
      "from" => @from,
      "message" => message,
      "time" => Time.now.strftime("%Y-%m-%d %H:%M:%S.%3N"),
      "response" => response
    })
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
    if @from.match(/^web/)
      response = "#{to}:#{message}"
    else # source was via web
      response = $gateways[@to].send_message(
        to,
        message,
        {
          "linkId" => @linkId,
          "bulkSMSMode" => if (@to == "20326") then 1 else 0 end # 1 needed for toll free
        }
      )
    end

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
    @state["results"].find_all{|result|
      (result["text"] == question_name or result["question_name"] == question_name) and result["valid"] == true
      (result["text"] == question_name or result["question_name"] == question_name) and result["valid"] == true
    }.max_by{|result|
      result["datetime"]
    }["answer"]
  end

  def add_and_save_results(results)
    @state["results"] += results
    #save_state()
  end
  

  ###
  # For reusing previous answers
  ###

  def last_question_set_response
    result = $db.view("complete_results_by_question_set_and_phone_number_and_date/complete_results_by_question_set_and_phone_number_and_date", {
      "startkey" => [@state["question_set"], @from, {}],
      "endkey" => [@state["question_set"], @from],
      "limit" => 1,
      "descending" => true,
      "include_docs" => false
    })['rows']
    if result.length == 1
      return result[0]
    else
      return nil
    end
  end

  def relevant_previous_results
    return_val = relevant_previous_results_with_updated_at()
    return_val.delete("updated_at") if return_val
    return_val
  end

  def relevant_previous_results_with_updated_at
    last_response = self.last_question_set_response()
    if last_response
      return last_response['value'].reject do |question, answer|
        QuestionSets.get_question_set(@state["question_set"])["exclude_from_previous_results"].include?(question)
      end
    end
  end

  def load_previous_results_if_confirmed(confirmed)
    # set @state to have the previous data loaded
    return false if confirmed == 'N'

    previous_results = relevant_previous_results_with_updated_at()

    load_results(previous_results, previous_results['updated_at'], "previous_results")

    return nil
  end

  def load_results_from_database_doc(database_name, doc_id)
    puts "Loading results from code"
    begin
      results = CouchRest.database("http://localhost:5984/#{database_name}").get(doc_id).to_hash
    rescue
      puts "Could not find result for #{doc_id} in #{database_name}"
      return doc_id
    end

    # Skip _id and _rev but treat the property name as the question name and load it
    results = results.reject{|property,value| property.start_with?('_') }

    load_results(results.reject{|property,value| property.start_with?('_') }, Time.now.to_s , "#{database_name}:#{doc_id}")
    return doc_id
  end

  def load_results(results, datetime, source)
    puts "Loading results: #{results}"
    question_set = QuestionSets.get_question_set(@state["question_set"])


    results.each do |question, answer|
      next if question == "updated_at"
      next if answer.nil?

      question_index = -1 # This needs to be -1 so that the first index will be 0
      question_in_question_set = question_set["questions"].find do |question_set_question|
        question_index+=1
        question_set_question["name"] == question or question_set_question["text"] == question
      end
      puts "Couldn't match previous question: #{question} with current questions: #{question_set["questions"]}\n so skipping it and will re-ask" if question_in_question_set.nil?
      next if question_in_question_set.nil?

      next unless validation_message(question_in_question_set["validation"], answer).nil?

      @state["results"].push({
        "question_index" => question_index,
        "question_name" => question_in_question_set["name"],
        "question" => question_in_question_set["text"],
        "answer" => answer,
        "valid" => @validation_message ? @validation_message : true,
        "datetime" => datetime,
        "source" => source
      })
    end
  end


end

