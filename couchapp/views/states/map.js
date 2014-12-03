function(doc) {
  if(doc.from){
    emit(doc.from, null);
  }
}
