(doc) ->
  if doc.questions and doc.trigger_words
    for trigger_word in doc.trigger_words
      emit trigger_word.toUpperCase(), doc._id
