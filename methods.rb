
def get_csv(question_set)

  header = QuestionSets.get_questions(question_set).map{ |question|
    "\"#{question["text"]}\""
  }.join(",")

  results = $db.view("results_by_question_set/results_by_question_set", {
    "key" => question_set,
    "include_docs" => false
  })['rows'].map do |result|
    result["value"]
  end

  header + "\n" + results.map{ |result|
    column_counter = 0
    result.map{ |column,answer|
      column = column.to_i
      return_value = if column_counter == column 
        "\"#{answer}\"" 
      else
         ""
      end
      column_counter += 1
      return_value
    }.join(",")
  }.join("\n")
end

