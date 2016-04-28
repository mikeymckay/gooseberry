class QuestionSets

  def self.all
    $db.view("question_set/question_sets", {
    })['rows'].map{|row| row["key"]}
  end

  def self.get_question_set(question_set_name)
    begin
      $db.get question_set_name
    rescue
      nil
    end
  end

  def self.get_questions(question_set_name)
    QuestionSets.get_question_set(question_set_name)["questions"]
  end

  def self.report_headers(question_set_name)
    ["From","Last Updated"].concat(QuestionSets.get_questions(question_set_name).map{|question_set|question_set["text"]})
  end

end
