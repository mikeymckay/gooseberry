(function(doc) {
  if (doc.questions) return emit(doc._id, null);
});
