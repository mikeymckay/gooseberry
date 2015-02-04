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
    "raw/:phoneNumber/:questionSet": "viewRawResult"
    "log/:phoneNumber": "log"
    "analyze/:questionSet": "analyze"
    '*invalidRoute' : 'showErrorPage'

  interact: (name) ->
    target = document.location.hash.substring(document.location.hash.indexOf('=')+1)
    Gooseberry.interactView = new InteractView() unless Gooseberry.interactView
    Gooseberry.interactView.name = name
    Gooseberry.interactView.target = target
    Gooseberry.interactView.render()

  log: (phoneNumber) ->
    Gooseberry.logView = new LogView() unless Gooseberry.logView
    Gooseberry.logView.number = phoneNumber
    Gooseberry.viewLogDB
      name: "messages_by_number"
      startKey: [phoneNumber]
      endKey: [phoneNumber,{}]
      descending: true
      include_docs: false,
      success: (result) =>
        Gooseberry.logView.logData = result.rows
        Gooseberry.logView.render()

  viewRawResult: (phoneNumber,questionSet) ->
    Gooseberry.view
      name: "states"
      key: phoneNumber
      include_docs: true
      success: (result) ->
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
    ,
      success: ->
        Gooseberry.router.navigate "question_set/#{name}/edit",
          trigger: true

  editQuestionSet: (name) ->
    Gooseberry.questionSetEdit = new QuestionSetEdit() unless Gooseberry.questionSetEdit
    Gooseberry.questionSetEdit.fetchAndRender(name)

  questionSetResults: (name,startDate = moment().subtract(1,"week").format("YYYY-MM-DD"),endDate = moment().format("YYYY-MM-DD")) ->
    Gooseberry.questionSetResults = new QuestionSetResults() unless Gooseberry.questionSetResults
    Gooseberry.questionSetResults.startDate = startDate
    Gooseberry.questionSetResults.endDate = endDate
    Gooseberry.questionSetResults.name = name
    Gooseberry.questionSetResults.fetchAndRender()

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

