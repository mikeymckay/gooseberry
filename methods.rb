#set :bind, '0.0.0.0'

$database_name = "gooseberry"
$db = CouchRest.database("http://localhost:5984/#{$database_name}")

def get_csv(question_set)

  header = get_questions_for_question_set(question_set).map{ |question|
    "\"#{question["text"]}\""
  }.join(",")

  results = $db.view("#{$database_name}/results_by_question_set", {
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

def get_state(from,text)
  state = $db.view("#{$database_name}/states", {
    "key" => from,
    "include_docs" => true
  })['rows'].first

  return state["doc"] unless state.nil?

  return {
    "from" => from,
    "current_question_index" => nil,
    "results" => [
    ]
  }
end

def question_sets()
  $db.view("#{$database_name}/question_sets", {
  })['rows'].map{|row| row["key"]}
end

def get_question_set(question_set_name)
  $db.get question_set_name
end

def get_questions_for_question_set(question_set_name)
  get_question_set(question_set_name)["questions"]
end

def save_state(state)
  state["updated_at"] = Time.now.to_s
  state = $db.save_doc(state)
end

def send_message(to,message)
  if to == "web"
    "#{to}:#{message}"
  else
    $gateway.send_message(to, message)
  end
end

# validation helpers
#
def error_from_invalid_kenya_county(county_name)
  valid_counties = "Mombasa
Kwale
Kilifi
Tana River
Lamu
Taita-Taveta
Garissa
wajir
Mandera
Marsabit
Isiolo
Meru
Tharaka-Nithi
Embu
Kitui
Machakos
Makueni
Nyandarua
Nyeri
Kirinyaga
Murang'a
Kiambu
Turkana
West Pokot
Samburu
Trans Nzoia
Uasin Gishu
Elgeyo-Marakwet
Nandi
Baringo
Laikipia
Nakuru
Narok
Kajiado
Kericho
Bomet
Kakamega
Vihiga
Bungoma
Busia
Siaya
Kisumu
Homa Bay
Migori
Kisii
Nyamira
Nairobi City
".split(/\n/).map{|county|county.upcase}

  return nil if valid_counties.include? county_name.upcase
  closest_match = FuzzyMatch.new(valid_counties).find(county_name.upcase)
  return "#{county_name} is not a valid county. Do you mean #{closest_match}?"

end
