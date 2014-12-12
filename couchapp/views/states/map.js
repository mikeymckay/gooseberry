function(doc) {
  if(doc.from){
    emit(doc.from, doc.question_set);
  }
}
