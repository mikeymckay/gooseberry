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
      <pre id='editor'></pre>
    "

    editor = ace.edit('editor')
    editor.setTheme('ace/theme/twilight')
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
    @questionSet = new QuestionSet
      _id: name
    @questionSet.fetch
      success: =>
        @renderTableStructure()
        @questionSet.fetchResults
          success: (results) =>
            @renderTableContents(results)

  renderTableStructure: =>
    @$el.html "
      <table id='results'>
        <thead>
          #{
            _(@questionSet.questionStrings()).map (header) ->
              "<th>#{header}</th>"
            .join("")
          }
        </thead>
      </table>
    "

  renderTableContents: (results) =>
    $("#results").dataTable
      data: results

  events:
    "click button#save": "save"


class QuestionSetCollectionView extends Backbone.View
  el: '#content'

  events:
    "click td.name": "openQuestionSet"
    "click td.number-of-results": "openResults"

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
          <table>
            <thead>
              <th>Name</th><th>Number of results</th>
            </thead>
            <tbody>
              #{
               questionSets.map (questionSet) ->
                "
                  <tr data-name='#{questionSet.name()}'>
                    <td class='name clickable-row'>#{questionSet.name()}</td>
                    <td class='number-of-results'></td>
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
              console.log results.length
              $("tr[data-name='#{questionSet.name()}'] td.number-of-results").html results.length

