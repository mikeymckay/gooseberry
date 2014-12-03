class Message

  def initialize(options)
    @from = options["from"] # The number that sent the message
    @to = options["to"]     # The number to which the message was sent
    @text = options["text"] # The message content
    @date = options["date"] # The date and time when the message was received
    @id = options["id"]     # The internal ID that we use to store this message
    @linkId = options["linkId"] # Optional parameter required when responding to an on-demand user request with a premium message

  end


  def set_state
    state_view = $db.view("#{$database_name}/states", {
      "key" => @from,
      "include_docs" => true
    })['rows'].first

    if state_view.nil?
      @state = {
        "from" => @from,
        "current_question_index" => nil,
        "results" => [
        ]
      }
    else
      @state = state_view["doc"]
    end

  end

  def process_triggers
    case @text
      when /^Start (.+)/i
        @state["question_set"] = $1
      when /^Reset$/i
        @state["current_question_index"] = nil
        @state["results"] = []
      else
        if @state["question_set"].nil?
          send_message(from,"No question set loaded.")
          return false
        end
    end
    true
  end



  def process_answer
    @validation_message = nil
    @current_question_index = -1

    if @state["current_question_index"]
      @current_question_index = @state["current_question_index"]
      current_question = @questions[@current_question_index]

      answer = @text
      if current_question["post_process"]
        answer = eval "answer = '#{@text}';#{current_question["post_process"]}"
      end

      @validation_message = if current_question["validation"]
        eval "answer = '#{answer}';#{current_question["validation"]}"
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
      if skip_if 
        answers_hash = {}
        @state["results"].each do |result|
          index = result["question_name"] || result["question"]
          answers_hash[index] = result["answer"]
        end
        if(eval "answers = #{answers_hash};#{skip_if}")
          return send_next_message() #RECURSE
        end
      end

      @state["current_question_index"] = @current_question_index
      message = @questions[@current_question_index]["text"]
      message = "#{@validation_message}, try again: #{message}" if @validation_message
    else
      @state["current_question_index"] = nil
      message = "#{@state["question_set"]} is complete - thanks."
    end

    send_message(@from,message)
  end

  def save_state
    @state["updated_at"] = Time.now.to_s
    @state = $db.save_doc(@state)
  end

  def send_message(to,message)
    return "#{to}:#{message}"
  end

  def process
    set_state
    return unless process_triggers
    @questions = QuestionSets.get_questions(@state["question_set"])
    process_answer
    result = send_next_message
    # TODO check result to make sure message was sent before saving state
    save_state
    return result
  end

end

