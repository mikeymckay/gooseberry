class QuestionSets

  def self.all
    $db.view("#{$database_name}/question_sets", {
    })['rows'].map{|row| row["key"]}
  end

  def self.get_question_set(question_set_name)
    $db.get question_set_name
  end

  def self.get_questions(question_set_name)
    QuestionSets.get_question_set(question_set_name)["questions"]
  end

end
