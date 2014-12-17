(doc) ->
  if doc.from
    data = {
      invalidResult: {}
      validIndices: []
    }
    firstResultTime = null
    for result in doc.results
      firstResultTime = result.datetime unless firstResultTime
      if (result.valid isnt true)
        data.invalidResult[result.question_index] = result.answer
      if (result.valid)
        data.validIndices.push result.question_index

    #include metadata at the end of the array
    data["from"] = doc.from
    data["firstResultTime"] = firstResultTime
    data["updatedAt"] = doc.updated_at
    data["complete"] = doc.complete
    emit doc.question_set, data
