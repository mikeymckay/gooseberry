class QuestionSetView extends Backbone.View
  el: '#content'

  fetchAndRender: (name) ->
    @questionSet = new QuestionSet
      _id: name
    @questionSet.fetch
      success: =>
        @render()

  render: =>
    @$el.html "
      <a href='#question_set/#{@questionSet.name()}/edit'>Edit</a>
      <pre class='readonly' id='editor'></pre>
    "

    editor = ace.edit('editor')
    editor.setTheme('ace/theme/dawn')
    editor.setReadOnly(true)
    editor.getSession().setMode('ace/mode/json')
    json = @questionSet.toJSON()
    editor.setValue(JSON.stringify(json,null,2))

class QuestionSetEdit extends Backbone.View
  el: '#content'

  fetchAndRender: (name) ->
    @questionSet = new QuestionSet
      _id: name
    @questionSet.fetch
      success: =>
        @render()

  render: =>
    @$el.html "
      <button id='save' type='button'>Save</button>
      <pre id='editor'></pre>
    "

    @editor = ace.edit('editor')
    @editor.setTheme('ace/theme/twilight')
    @editor.getSession().setMode('ace/mode/json')
    json = @questionSet.toJSON()
    @editor.setValue(JSON.stringify(json,null,2))

  events:
    "click button#save": "save"

  save: =>
    Gooseberry.save
      doc: JSON.parse @editor.getValue()
      success: =>
        Gooseberry.router.navigate "question_set/#{@questionSet.name()}",
          trigger: true


class QuestionSetResults extends Backbone.View
  el: '#content'

  fetchAndRender: (name) ->
    @$el.html "
      <h1>#{name}</h1>
      <div id='stats'></div>
    "
    @questionSet = new QuestionSet
      _id: name
    @questionSet.fetch
      success: =>
        @renderTableStructure()
        @questionSet.fetchResults
          success: (results) =>
            @renderTableContents(results)
            @analyze()

  renderTableStructure: =>
    @$el.append "
      <table id='results'>
        <thead>
          #{
            _(@questionSet.questionStringsWithNumberAndDate()).map (header) ->
              "<th>#{header}</th>"
            .join("")
          }
        </thead>
        <tbody>
        </tbody>
      </table>
    "

  renderTableContents: (results) =>
    @$el.find("tbody").html(
      _(results).map (result) => "
        <tr>
          <td><a href='#log/#{result["from"]}/#{@questionSet.name()}'>#{result["from"]}</a></td>
          <td>#{result["updated_at"]}</td>
          #{
            _([0..@questionSet.questionStrings().length-1]).map (index) ->
              "<td>#{result[index] or "-"}</td>"
            .join("")
          }
        </tr>
      "
      .join("")
    )
    @$el.find("table").dataTable
      order: [[ 1, "desc" ]]
      iDisplayLength: 25
      dom: 'T<"clear">lfrtip'
      tableTools:
        sSwfPath: "js-libraries/copy_csv_xls_pdf.swf"



  analyze: =>
    Gooseberry.view
      name: "analysis_by_question_set"
      key: @questionSet.name()
      include_docs: false
      success: (results) =>
        completionDurations = []
        incompleteResults = []
        completeResults = 0
        mistakes = []
        requiredIndices = @questionSet.get "required_indices"
        requiredIndices = JSON.parse requiredIndices if requiredIndices?
        _(_(results.rows).pluck("value")).each (result) =>

          if requiredIndices?
            if _(requiredIndices).difference(result.validIndices).length is 0
              completeResults += 1
              if result.updatedAt and result.firstResultTime
                completionDurations.push moment(result.updatedAt).diff(moment(result.firstResultTime), "seconds")
            else
              incompleteResults.push result["from"]

          mistakes.push(result.invalidResult) unless _(result.invalidResult).isEmpty()

        mistakeCount = 0
        _(mistakes).each (mistake) =>
          _(mistake).each (value,index) =>
            mistakeCount += 1


        if requiredIndices
          totalResults = completeResults + incompleteResults.length
          incompletePercentage = "#{Math.floor(incompleteResults.length/totalResults*100)} %"
          mistakePercentage = "#{Math.floor(100 * mistakeCount/(totalResults*requiredIndices.length))} %"

        if completionDurations.length > 0
          fastestCompletion = moment.duration(_(completionDurations).min(), "seconds").humanize()
          slowestCompletion = moment.duration(_(completionDurations).max(), "seconds").humanize()
          medianTimeToComplete = moment.duration(math.median(completionDurations), "seconds").humanize()
          meanTimeToComplete = moment.duration(math.mean(completionDurations), "seconds").humanize()

        @$el.find("#stats").html "
          <ul>
            <li>Median Time To Complete: #{medianTimeToComplete} (Fastest: #{fastestCompletion} - Slowest: #{slowestCompletion})
            <!--
            <li>Mean Time To Complete: #{meanTimeToComplete}
            -->
            <li>Number of incomplete results: <button type='button' id='toggleIncompletes'>#{incompleteResults.length}</button> (#{incompletePercentage}) <a href='http://gooseberry.tangerinecentral.org/send_reminders/#{@questionSet.name()}/240'>Send reminder SMS</a>
            <li>Total number of validation failures: <button id='toggleMistakes' type='button'>#{mistakeCount}</button> (#{mistakePercentage})
          </ul>
          <div id='incompleteResultsDetails' style='display:none'>
            <h2>Incomplete Results</h2>
            <ul>
            #{
              _(incompleteResults).map (number) =>
                "
                  <li>#{number}
                "
              .join("")
            }
            </ul>
          </div>
          <div id='mistakeDetails' style='display:none'>
            <h2>Validation Failures</h2>
            <table>
              <thead>
                <td>Question</td>
                <td>Answer</td>
              </thead>
              <tbody>
              #{
                _(mistakes).map (mistake) =>
                  _(mistake).map (value,index) =>
                    "
                      <tr>
                        <td>#{@questionSet.questionStrings()[index]}</td>
                        <td>#{value or ""}</td>
                      </tr>
                    "
                  .join("")
                .join("")
              }
              </tbody>
            </table>
          </div>
        "
        
  toggleIncompletes: -> $("#incompleteResultsDetails").toggle()
  toggleMistakes: -> $("#mistakeDetails").toggle()

  events:
    "click button#save": "save"
    "click button#toggleMistakes": "toggleMistakes"
    "click button#toggleIncompletes": "toggleIncompletes"




class QuestionSetCollectionView extends Backbone.View
  el: '#content'

  events:
    "click td.name": "openQuestionSet"
    "click td.number-of-results": "openResults"
    "click #toggleNew": "toggleNew"
    "click #create": "create"
    "click #delete": "delete"
    "click #reallyDelete": "reallyDelete"
    "click #cancel": "cancel"
    "click #copy": "copy"
    "click #createCopy": "createCopy"
    "click #interact": "interact"

  interact: (event) =>
    name = $(event.target).closest("tr").attr("data-name")
    #target = "http://localhost:9393/22340/incoming"
    target = "http://gooseberry.tangerinecentral.org/22340/incoming"
    Gooseberry.router.navigate "interact/#{name}?target=#{target}", {trigger: true}

  cancel: ->
    $("deleteMessage").html ""

  copy: (event) =>
    @copySource = $(event.target).closest("tr").attr("data-name")
    $("#copyForm").html "
      <input style='text-transform: uppercase' id='copyFormField' value='COPY OF #{@copySource}'></input><button id='createCopy'>Create</button>
    "

  createCopy: =>
    questionSet = new QuestionSet
      _id: @copySource
    questionSet.fetch
      success: =>
        questionSet.clone()
        questionSet.set "_id", $("#copyFormField").val().toUpperCase()
        questionSet.unset "_rev"
        questionSet.save
          success: =>
            console.log "AAA"
            @render()
          error: =>
            console.log "RAA"

  reallyDelete: =>
    questionSet = new QuestionSet
      _id: @deleteTarget
    questionSet.fetch
      success: =>
        questionSet.destroy
          success: =>
            @render()

  delete: (event) =>
    @deleteTarget = $(event.target).closest("tr").attr("data-name")
    $("#deleteMessage").html "Are you sure you want to delete #{@deleteTarget}? <button id='reallyDelete'>Yes</button><button id='cancelDelete'>Cancel</button>"

  create: ->
    newName = $("#newName").val().toUpperCase()
    if newName
      Gooseberry.router.navigate "question_set/#{newName}/new", {trigger: true}

  toggleNew: ->
    $("#new").toggle()

  openResults: (event) ->
    name = $(event.target).closest("tr").attr("data-name")
    Gooseberry.router.navigate "question_set/#{name}/results",
      trigger: true

  openQuestionSet: (event) ->
    name = $(event.target).closest("tr").attr("data-name")
    Gooseberry.router.navigate "question_set/#{name}",
      trigger: true

  render: =>
    questionSets = new QuestionSetCollection()
    questionSets.fetch
      success: =>
        @$el.html "
          <h1>Question Sets</h1>
          <button id='toggleNew'>New</button>
          <br/>
          <div style='display:none' id='new'>
            <br/>
            Name:  <input id='newName' style='text-transform: uppercase' type='text'></input>
            <button id='create'>Create</button>
            <br/>
          </div>
          <br/>
          <div id='deleteMessage'></div>
          <div id='copyForm'></div>
          <table>
            <thead>
              <th>Name</th><th>Number of results</th><th/><th/>
            </thead>
            <tbody>
              #{
               questionSets.map (questionSet) ->
                "
                  <tr data-name='#{questionSet.name()}'>
                    <td class='name clickable'>#{questionSet.name()}</td>
                    <td class='clickable number-of-results'></td>
                    <td><small><button id='interact'>interact</button></small></td>
                    <td><small><button id='delete'>x</button></small></td>
                    <td><small><button id='copy'>copy</button></small></td>
                  </tr>
                "
               .join("")
              }
            </tbody>
          </table>
        "
        questionSets.each (questionSet) ->
          questionSet.fetchResults
            success: (results) ->
              $("tr[data-name='#{questionSet.name()}'] td.number-of-results").html results.length

