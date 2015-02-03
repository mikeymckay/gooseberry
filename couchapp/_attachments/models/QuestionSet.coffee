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
        @results = _.pluck(result.rows, "value")
        options.success(@results)

  fetchAllResults: (options) =>
    Gooseberry.view
      name: "results_by_question_set"
      key: @id
      include_docs: false
      success: (result) ->
        @results = _.pluck(result.rows, "value")
        options.success(@results)

  questionStrings: =>
    _(@get("questions")).map (questionData) ->
      questionData.name or questionData.text

  questionStringsWithNumberAndDate: =>
    ["From","Date"].concat @questionStrings()

class QuestionSetCollection extends Backbone.Collection
  model: QuestionSet
  url: "/question_set"

  fetch: (options = {}) ->
    options["include_docs"] = true
    super(options)
