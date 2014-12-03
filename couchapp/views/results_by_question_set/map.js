(function(doc) {
  var data, result, _i, _len, _ref;
  if (doc.from) {
    data = {};
    _ref = doc.results;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      result = _ref[_i];
      if (result.valid) data[result.question_index] = result.answer;
    }
    return emit(doc.question_set, data);
  }
});
