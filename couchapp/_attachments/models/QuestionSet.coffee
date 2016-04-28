_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
moment = require 'moment'

class QuestionSet extends Backbone.Model
  name: => @id

  fetchResultsForDates: (options) =>
    Gooseberry.database.query "results_by_question_set_and_date/results_by_question_set_and_date",
      startkey: [@id,options.startDate]
      endkey: [@id,moment(options.endDate).add(1,"day").format("YYYY-MM-DD")] #set to next day
      include_docs: false
      reduce: false
    .catch (error) -> console.error error
    .then (result) =>
      @results = result.rows
      options.success(@results)

  fetchAllResults: (options) =>
    Gooseberry.database.query "results_by_question_set_and_date/results_by_question_set_and_date",
      startkey: [@id]
      endkey: [@id,{}]
      include_docs: false
      reduce: false
    .catch (error) -> console.error error
    .then (result) =>
      @results = _.pluck(result.rows, "value")
      options.success(@results)

  resultCount: (options) =>
    Gooseberry.database.query "results_by_question_set_and_date/results_by_question_set_and_date",
      startkey: [@id]
      endkey: [@id,{}]
      include_docs: false
      reduce: true
      group_level: 1
    .catch (error) -> console.error error
    .then (result) =>
      count = result.rows[0]?.value or 0
      options.success(count)

  questionStrings: =>
    _(@get("questions")).map (questionData) ->
      questionData.name or questionData.text

  orderedDataFields: =>
    columnOrder = @get "column order"
    if columnOrder
      columnsNotIncludedInOrderList = _.difference(@questionStrings(),columnOrder)
      columnOrder.concat(columnsNotIncludedInOrderList).concat(["complete","from","updated_at"]).concat(@get "other_data")
    else
      @dataFields()

  dataFields: =>
    ["complete","from","updated_at"].concat(@questionStrings()).concat(@get "other_data")

  dataIndexes: =>
    ["complete","from","updated_at"].concat([0..(@questionStrings().length-1)]).concat(@get "other_data")

module.exports = QuestionSet
