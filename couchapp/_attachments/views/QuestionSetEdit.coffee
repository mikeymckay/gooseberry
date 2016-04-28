$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
_ = require 'underscore'

QuestionSet = require '../models/QuestionSet'
ace = require 'brace'
require 'brace/mode/json'
require 'brace/theme/twilight'

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
    Gooseberry.database.put JSON.parse @editor.getValue()
    .catch (error) -> console.error error
    .then =>
      Gooseberry.router.navigate "question_set/#{@questionSet.name()}",
        trigger: true

module.exports = QuestionSetEdit
