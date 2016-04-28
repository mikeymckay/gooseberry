_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
QuestionSet = require '../models/QuestionSet'
PouchDB = require 'pouchdb'
BackbonePouch = require 'backbone-pouch'

class QuestionSetCollection extends Backbone.Collection
  model: QuestionSet

  sync: BackbonePouch.sync
    db: Gooseberry.database
    fetch: 'query'
    options:
      query:
        include_docs: true
        fun: "question_sets/question_sets"

  parse: (result) ->
    _.pluck(result.rows, 'doc')

module.exports = QuestionSetCollection
