(doc) ->
  if doc.complete? and doc.complete is false
    emit([doc.question_set,doc.from],[doc.times_reminders_sent,doc.updated_at])
