(doc) ->
  if doc.from and doc.results[0] and doc.complete
    data = {}
    for result in doc.results
      if (result.valid)
        data[result.question_name or result.question] = result.answer if (result.valid)
    if doc.other_data
      for property,value of doc.other_data
        data[property] = value
    #include metadata at the end of the array
    data["from"] = doc.from
    data["updated_at"] = doc.updated_at
    emit [doc.question_set,doc.from,doc.updated_at], data
