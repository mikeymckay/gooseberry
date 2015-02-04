(doc) ->
    number = if doc.type is "sent"
      doc.to
    else if doc.type is "incoming"
      doc.from

    if number
      emit [number,doc.time], [doc.type,doc.message]
