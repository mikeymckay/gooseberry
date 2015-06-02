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

      <h2>Documentation</h2>
      other_data can be set by calling add_data({'name' => 'value'})
      If they are listed, then they will also be used for the spreadsheet
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
  constructor: ->
    super()
    $.couch.db("gooseberry").changes null,
      view: "results_by_question_set"
      include_docs: true
    .onChange (data) =>
      #@fetchAndRender()
      #return
      _(data.results).each (result) =>
        # Only add rows for this question set
        return unless result.key[0] is @name

        # Need this to match the results_by_question set view output
        questionSetResult = {
          id: result.doc._id
          value: {
            compete: result.doc.complete
            from: result.doc.from
            updated_at: result.doc.updated_at
          }
        }

        if result.doc.results

          for result in result.doc.results
            if result.valid
              questionSetResult.value[result.question_index] = result.answer

        @updateTableContents(questionSetResult)

  el: '#content'

  fetchAndRender: () =>
    @$el.html "
      <h1>#{@name}</h1>
      <input id='startDate' type='date' value='#{@startDate}'></input>
      <input id='endDate' type='date' value='#{@endDate}'></input>
      <div id='stats'></div>
    "
    @questionSet = new QuestionSet
      _id: @name
    @questionSet.fetch
      success: =>
        @renderTableStructure()
        @questionSet.fetchResultsForDates
          startDate: @startDate
          endDate: @endDate
          success: (results) =>
            @renderTableContents(results)
            @analyze()

  renderTableStructure: =>
    @$el.append "
      <table id='results'>
        <thead>
          #{
            _(@questionSet.dataFields()).map (header) ->
              "<th>#{header}</th>"
            .join("")
          }
        </thead>
        <tbody>
        </tbody>
      </table>
    "

  rowDataForQuestionSetResult: (questionSetResult) =>
    result = questionSetResult.value
    returnValue =  [
      result["complete"] || "false"
      "#{result["from"]} <small><a href='#log/#{result["from"]}'>Log</a></small></td>"
      result["updated_at"]
    ]
    _([0..@questionSet.questionStrings().length-1]).each (index) ->
      returnValue.push "#{result[index] or "-"}"

    (@questionSet.dataIndexes()).map (dataField) ->
      result[dataField]


  rowForQuestionSetResult: (questionSetResult) =>
    result = questionSetResult.value
    "
      <tr id='#{questionSetResult.id}' #{if result.complete isnt true then "class='incomplete'" else ""} >
        #{
          @rowDataForQuestionSetResult(questionSetResult).map (element) ->
            "<td>#{element or "-"}</td>"
          .join("")
        }
      </tr>
    "

  updateTableContents: (questionSetResult) =>
    existingRowForResult = $("##{questionSetResult.id}")
    if existingRowForResult.length != 0
      row = @rowForQuestionSetResult(questionSetResult)
      existingRowForResult.replaceWith row
    else
      dataTable = $("#results").DataTable()
      dataTable.row.add(@rowDataForQuestionSetResult(questionSetResult)).draw()
    
  renderTableContents: (results) =>
    @$el.find("tbody").html(
      _(results).map (result) =>
        @rowForQuestionSetResult(result)
      .join("")
    )
    @$el.find("table#results").dataTable
      order: [[ 2, "desc" ]]
      iDisplayLength: 25
      dom: 'T<"clear">lfrtip'
      tableTools:
        sSwfPath: "js-libraries/copy_csv_xls_pdf.swf"



  analyze: =>
    Gooseberry.view
      name: "analysis_by_question_set"
      startkey: [@questionSet.name(),@startDate]
      endkey: [@questionSet.name(),moment(@endDate).add(1,"day").format("YYYY-MM-DD")] #set to next day
      include_docs: false
      success: (results) =>
        completionDurations = []
        incompleteResults = []
        completeResults = 0
        mistakes = []
        _(_(results.rows).pluck("value")).each (result) =>

          if result.complete is true
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


        totalResults = completeResults + incompleteResults.length
        incompletePercentage = "#{Math.floor(incompleteResults.length/totalResults*100)} %"
        mistakePercentage = "#{Math.floor(100 * mistakeCount/(totalResults))} %"

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
            <li>Number of incomplete results: <button type='button' id='toggleIncompletes'>#{incompleteResults.length}</button> (#{incompletePercentage}) <!--<a href='http://gooseberry.tangerinecentral.org/send_reminders/#{@questionSet.name()}/240'>Send reminder SMS</a>-->
            <li>Total number of validation failures: <button id='toggleMistakes' type='button'>#{mistakeCount}</button> (#{mistakePercentage})
          </ul>
          <div id='incompleteResultsDetails' style='display:none'>
            <h2>Incomplete Results</h2>
            <ul>
            #{
              _(incompleteResults).map (number) =>
                "
                  <li><a href='#log/#{number}'>#{number}</a>
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

  updateDate: =>
    Gooseberry.router.navigate "question_set/#{@name}/results/#{$("#startDate").val()}/#{$("#endDate").val()}", {trigger: true}
    

  events:
    "click button#save": "save"
    "click button#toggleMistakes": "toggleMistakes"
    "click button#toggleIncompletes": "toggleIncompletes"
    "change #startDate": "updateDate"
    "change #endDate": "updateDate"




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
    target = Gooseberry.config.messageTarget
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
        questionSet.save null,
          success: =>
            console.log "RENDERING"
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
    console.log "RENDER"
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
          questionSet.fetchAllResults
            success: (results) ->
              $("tr[data-name='#{questionSet.name()}'] td.number-of-results").html results.length

