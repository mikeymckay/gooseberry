// Generated by CoffeeScript 1.9.0
(function(doc) {
  var data, property, result, startTime, value, _i, _len, _ref, _ref1;
  if (doc.from && doc.results[0]) {
    data = {
      complete: doc.complete
    };
    startTime = doc.results[0].datetime;
    _ref = doc.results;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      result = _ref[_i];
      if (result.valid) {
        data[result.question_index] = result.answer;
      }
    }
    if (doc.other_data) {
      _ref1 = doc.other_data;
      for (property in _ref1) {
        value = _ref1[property];
        data[property] = value;
      }
    }
    data["from"] = doc.from;
    data["updated_at"] = doc.updated_at;
    return emit([doc.question_set, startTime], data);
  }
});

//# sourceMappingURL=map.js.map
