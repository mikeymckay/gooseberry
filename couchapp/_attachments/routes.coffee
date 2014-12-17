class Router extends Backbone.Router
  routes:
    "": "questionSets"
    "question_sets": "questionSets"
    "question_set/:name": "questionSet"
    "question_set/:name/edit": "editQuestionSet"
    "question_set/:name/results": "questionSetResults"
    "log/:phoneNumber/:questionSet": "log"
    "analyze/:questionSet": "analyze"
    '*invalidRoute' : 'showErrorPage'

  log: (phoneNumber,questionSet) ->
    Gooseberry.view
      name: "states"
      key: phoneNumber
      include_docs: true
      success: (result) ->
        console.log result
        state = (_(result.rows).find (result) ->
          result.value[0] is questionSet
        ).doc

        $("#content").html "
          <a href='#question_set/#{questionSet}/results'>#{questionSet} Results</a>
          <pre class='readonly' id='editor'></pre>
        "

        editor = ace.edit('editor')
        editor.setTheme('ace/theme/dawn')
        editor.setReadOnly(true)
        editor.getSession().setMode('ace/mode/json')
        json = state.results
        editor.setValue(JSON.stringify(json,null,2))

  analyze: (questionSet) ->
    $("#content").html "
    "

  questionSets: () ->
    Gooseberry.questionSetCollectionView = new QuestionSetCollectionView() unless Gooseberry.questionSetView
    Gooseberry.questionSetCollectionView.render()

  questionSet: (name) ->
    Gooseberry.questionSetView = new QuestionSetView() unless Gooseberry.questionSetView
    Gooseberry.questionSetView.fetchAndRender(name)

  editQuestionSet: (name) ->
    Gooseberry.questionSetEdit = new QuestionSetEdit() unless Gooseberry.questionSetEdit
    Gooseberry.questionSetEdit.fetchAndRender(name)

  questionSetResults: (name) ->
    Gooseberry.questionSetResults = new QuestionSetResults() unless Gooseberry.questionSetResults
    Gooseberry.questionSetResults.fetchAndRender(name)

  userLoggedIn: (callback) ->
    User.isAuthenticated
      success: (user) ->
        callback.success(user)
      error: ->
        Gooseberry.loginView.callback = callback
        Gooseberry.loginView.render()

  csv: (question,startDate,endDate) ->
    @userLoggedIn
      success: ->
        if User.currentUser.hasRole "reports"
          csvView = new CsvView
          csvView.question = question
          csvView.startDate = endDate
          csvView.endDate = startDate
          csvView.render()

  showErrorPage: () ->
    $("#content").html "No matching route"

