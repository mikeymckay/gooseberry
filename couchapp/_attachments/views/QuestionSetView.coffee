$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
_ = require 'underscore'
QuestionSet = require '../models/QuestionSet'
CronUI = require 'cron-ui'
Cronstrue = require 'cronstrue'

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
      <style>
        .editor {
          margin: 0;
          height: 50%;
          top: 20px;
          bottom: 0;
          left: 0;
          right: 0;
        }
      </style>
      <h2>#{@questionSet.name()}</h2>
      <a href='#question_set/#{@questionSet.name()}/edit'>Edit</a>
      <pre class='readonly editor' id='editor'></pre>
    "

    editor = ace.edit('editor')
    editor.setTheme('ace/theme/dawn')
    editor.setReadOnly(true)
    editor.getSession().setMode('ace/mode/json')
    json = @questionSet.toJSON()
    editor.setValue(JSON.stringify(json,null,2))

    additionalDataId = "#{@questionSet.name()}_data"

    Gooseberry.database.get additionalDataId
    .then (@data) =>
      @$el.append "
        <br/>
        <br/>
        <br/>
        <br/>
        <br/>
        <h3>Additional data for #{@questionSet.name()}:</h3>
        <a href='#question_set/#{additionalDataId}/edit'>Edit</a>
        <div id='initiating'></div>
        <pre class='readonly editor' id='question-set-data'></pre>
      "
      if @data.recipients
        @$("#initiating").html "
          <br/>
          <button id='initiate'>Initiate SMS to all recipients now</button>
          <br/>
          <br/>
          #{
            if @data.schedule
              "
                <div>
                  Currently set to initiate SMS to all recipients #{Cronstrue.toString(@data.schedule)}.
                  <div id='newSchedule'>
                    Update this to initiate SMS to all recipients every <span id='schedule'></span>
                    <button id='saveSchedule'>Save</button>
                  </div>
                </div>
              "
            else
              "
                <div id='newSchedule'>
                  No schedule is set. Initiate SMS to all recipients every <span id='schedule'></span>
                  <button id='saveSchedule'>Save</button>
                </div>
              "
          }
        "

        @cronUi = new CronUI('#schedule', {initial: @data.schedule or '0 9 * * 1'})
        $("#schedule").on "change", (newSchedule) =>
          @$("#saveSchedule").show()

      editor = ace.edit('question-set-data')
      editor.setTheme('ace/theme/dawn')
      editor.setReadOnly(true)
      editor.getSession().setMode('ace/mode/json')
      editor.setValue(JSON.stringify(@data,null,2))
    .catch (error) =>
      console.log error
      console.info "No extra data file for #{@questionSet.name()}"

  events:
    "click #initiate": "initiate"
    "click #saveSchedule": "saveSchedule"

  initiate: =>
    console.log "Initiate"

  saveSchedule: =>
    @data.schedule = @cronUi.getCronString()
    Gooseberry.database.put @data
    .then => @render()

module.exports = QuestionSetView
