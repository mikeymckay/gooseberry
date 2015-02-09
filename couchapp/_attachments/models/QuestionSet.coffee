class QuestionSet extends Backbone.Model
  url: "/question_set"

  name: => @id

  fetchResultsForDates: (options) =>
    Gooseberry.view
      name: "results_by_question_set"
      startkey: [@id,options.startDate]
      endkey: [@id,moment(options.endDate).add(1,"day").format("YYYY-MM-DD")] #set to next day
      include_docs: false
      success: (result) ->
        @results = result.rows
        #@results = _.pluck(result.rows, "value")
        options.success(@results)

  fetchAllResults: (options) =>
    Gooseberry.view
      name: "results_by_question_set"
      startkey: [@id]
      endkey: [@id,{}]
      include_docs: false
      success: (result) ->
        @results = _.pluck(result.rows, "value")
        options.success(@results)

  questionStrings: =>
    _(@get("questions")).map (questionData) ->
      questionData.name or questionData.text

  dataFields: =>
    ["complete","from","updated_at"].concat(@questionStrings()).concat(@get "other_data")

  dataIndexes: =>
    ["complete","from","updated_at"].concat([0..(@questionStrings().length-1)]).concat(@get "other_data")

class QuestionSetCollection extends Backbone.Collection
  model: QuestionSet
  url: "/question_set"

  fetch: (options = {}) ->
    options["include_docs"] = true
    super(options)
