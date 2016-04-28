def get_rows(question_set)
  headers = QuestionSets.report_headers(question_set)

  results = $db.view("results/results_by_question_set", {
    "key" => question_set,
    "include_docs" => false
  })['rows'].map do |result|
    result["value"]
  end
  
  results.map{ |result|
    [result["from"],result["updated_at"]].concat 0.upto(headers.length).map{ |column|
      answer = result[column.to_s]
      if answer
        answer
      else
        ""
      end
    }
  }

end

def get_csv(question_set)

  csv_header = QuestionSets.report_headers(question_set).map{ |header|
    "\"#{header}\""
  }.join(",")

  csv_rows = get_rows(question_set).map do |row|
    row.map{|element|"\"#{element}\""}.join(",")
  end

  csv_header + "\n" + csv_rows.join("\n")
end


def get_table(question_set)

  theader = QuestionSets.report_headers(question_set).map{ |header|
    "<th>#{header}</th>"
  }.join("")

  tbody_rows = get_rows(question_set).map do |row|
    row.map{|element|"<td>"+element+"</td>"}.join("")
  end

  "
  <table>
  <thead>
    <tr>
      #{theader}
    </tr>
  </thead>
    #{tbody_rows.map{|row| "<tr>" + row + "</tr>" }.join("")}
  </table>
  "
end

