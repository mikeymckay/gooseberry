$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
_ = require 'underscore'
QuestionSet = require '../models/QuestionSet'
ace = require 'brace'
require 'brace/mode/json'
require 'brace/theme/dawn'

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

module.exports = QuestionSetView
