(doc) ->
  if doc.from
    data = {}
    for result in doc.results
      if (result.valid)
        data[result.question_index] = result.answer
    #include metadata at the end of the array
    data["from"] = doc.from
    data["updated_at"] = doc.updated_at
    emit doc.question_set, data
