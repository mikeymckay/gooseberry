#usr/local/bin/coffee

PouchDB = require 'pouchdb'
_ = require 'underscore'

database = new PouchDB("http://localhost:5984/gooseberry")
database.query "results_by_question_set_and_date",
  startkey: ["TUSOMETEACHER","2016-01-01"]
  #startkey: ["TUSOMETEACHER","2016-11-01"]
  endkey: ["TUSOMETEACHER","2016-12-01"]
  reduce: false
.then (result) ->
  headers = {}
  _(result.rows).each (row) ->
    _(row.value).each (value,key) -> headers[key] = true
  console.log '"' + _(headers).keys().join('","') + '"\n"'
  _(result.rows).each (row) ->
    console.log(_(headers).map (val,header) ->
      if row.value[header]?
        '"' + row.value[header].toString().replace(/"/,"\"") + '"'
      else
        ""
    .join(","))
  
.catch (error) ->
  console.error error, error.stack.split("\n")
