$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
_ = require 'underscore'
moment = require 'moment'

InteractView = require './views/InteractView.coffee'
LogView = require './views/LogView.coffee'
QuestionSet = require './models/QuestionSet.coffee'
QuestionSetView = require './views/QuestionSetView.coffee'
QuestionSetEdit = require './views/QuestionSetEdit.coffee'
QuestionSetResultsView = require './views/QuestionSetResultsView.coffee'
QuestionSetCollectionView = require './views/QuestionSetCollectionView.coffee'

ace = require 'brace'
require 'brace/mode/json'
require 'brace/theme/dawn'

class Router extends Backbone.Router
  routes:
    "": "questionSets"
    "question_sets": "questionSets"
    "question_set/:name": "questionSet"
    "question_set/:name/new": "newQuestionSet"
    "question_set/:name/edit": "editQuestionSet"
    "question_set/:name/results": "questionSetResults"
    "question_set/:name/results/:startDate/:endDate": "questionSetResults"
    "interact/:name": "interact"
    "recent/messages": "recentMessages"
    '*invalidRoute' : 'showErrorPage'

  recentMessages: ->
    $("#content").html "
      <table>
      </table>

    "
    Gooseberry.logDatabase.changes
      limit: 10
      live: true
      since: "now"
      include_docs: true
      descending: true
    .on "change", (change) ->
      console.log change
      console.log "FOO"
      $("#content table").append "
        <tr>
          <td>
            #{change.doc.type}
          </td>
          <td>
            #{change.doc.message}
          </td>
        </tr>
      "

  interact: (name) ->
    target = document.location.hash.substring(document.location.hash.indexOf('=')+1)
    Gooseberry.interactView = new InteractView() unless Gooseberry.interactView
    Gooseberry.interactView.name = name
    Gooseberry.interactView.target = target
    Gooseberry.interactView.render()


  questionSets: () ->
    Gooseberry.questionSetCollectionView = new QuestionSetCollectionView() unless Gooseberry.questionSetCollectionView
    Gooseberry.questionSetCollectionView.render()

  questionSet: (name) ->
    Gooseberry.questionSetView = new QuestionSetView() unless Gooseberry.questionSetView
    Gooseberry.questionSetView.fetchAndRender(name)

  newQuestionSet: (name) ->
    questionSet = new QuestionSet
      _id: name.toUpperCase()
    questionSet.save
      questions: []
      type: "question"
    ,
      success: ->
        Gooseberry.router.navigate "question_set/#{name}/edit",
          trigger: true

  editQuestionSet: (name) ->
    Gooseberry.questionSetEdit = new QuestionSetEdit() unless Gooseberry.questionSetEdit
    Gooseberry.questionSetEdit.fetchAndRender(name)

  questionSetResults: (name,startDate = moment().subtract(1,"week").format("YYYY-MM-DD"),endDate = moment().format("YYYY-MM-DD")) ->
    Gooseberry.questionSetResultsView = new QuestionSetResultsView() unless Gooseberry.questionSetResultsView
    Gooseberry.questionSetResultsView.startDate = startDate
    Gooseberry.questionSetResultsView.endDate = endDate
    Gooseberry.questionSetResultsView.questionSet = new QuestionSet {_id: name}
    Gooseberry.questionSetResultsView.questionSet.fetch
      error: (error) -> console.error error
      success: -> Gooseberry.questionSetResultsView.render()

  userLoggedIn: (callback) ->
    User.isAuthenticated
      success: (user) ->
        callback.success(user)
      error: ->
        Gooseberry.loginView.callback = callback
        Gooseberry.loginView.render()

  showErrorPage: () ->
    $("#content").html "No matching route"


module.exports = Router
