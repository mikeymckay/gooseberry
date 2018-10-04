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

moment = require 'moment'
CsvToJson = require 'csvtojson'


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

    additionalDataId = "data_#{@questionSet.name()}"

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
          <div id='recipients'>
            <textarea style='width:100%;height:200px' id='csvRecipients'></textarea>
            <br/>

            <button id='updateRecipients'>Update Recipients</button>
          </div>
          #{
            if @data.schedule
              "
                <div>
                  Currently set to initiate SMS to all recipients #{Cronstrue.toString(@data.schedule)} from number: <input id='numberToSendFrom' value='#{@data.numberToSendFrom}'></input>.
                  <div id='newSchedule'>
                    Update this to initiate SMS to all recipients every <span id='schedule'></span>
                    <button id='saveSchedule'>Save</button>
                  </div>
                </div>
              "
            else
              "
                <div id='newSchedule'>
                  No schedule is set. Initiate SMS to all recipients every <span id='schedule'></span> from number: <input id='numberToSendFrom' value='#{@data.numberToSendFrom}'></input>.

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
    "click #updateRecipients": "updateRecipients"

  updateRecipients: =>

    CsvToJson(
      delimiter: ["	"] # this is tab, since that is what copy/paste from OpenOffice does
    ).fromString( @$("#csvRecipients").val() )
    .then (recipients) =>
      @data.recipients = recipients
      Gooseberry.database.put @data
      .then =>
        @createScriptedQuestionSetDataForRecipients()
      .then =>
        @render()
      .catch (error) =>
        alert error

  cleanPhoneNumber: (number) =>
    number.toString().replace(/^07|^7/,"+2547").replace(/^254/,"+254")

  createScriptedQuestionSetDataForRecipients: =>
    docs = _(@data.recipients).map (recipient) =>
      phoneNumber = @cleanPhoneNumber(recipient["Phone number"] or recipient["phone number"])
      updatedAt = moment().format("YYYY-MM-DD HH:MM:SS")

      doc = {
       "_id": "scripted_result_#{phoneNumber}_#{updatedAt.replace(/ /,"_")}",
       "from": phoneNumber
       "complete": true,
       "question_set": "READINGWITHKIDS",
       "updated_at": updatedAt,
       "results":[]

      }
      _(recipient).each (value, property) =>
        if property.toLowerCase().match(/phone number/)
          value = @cleanPhoneNumber(value)
        doc["results"].push
         "question_name": property.toLowerCase()
         "answer": value
         "valid": true
      doc

    Gooseberry.database.bulkDocs(docs)

  initiate: =>
    processAllRecipients = =>
      return if @data.recipients.length is 0
      recipient = @data.recipients.pop()
      console.log recipient
      request.post "http://gooseberry.tangerinecentral.org/#{@data.numberToSendFrom}/incoming",
        form:
          to: @data.numberToSendFrom
          from: recipient["phone number"]
          text: "START #{@questionSet.name()}"
          plain: true
      .on "response", =>
        _.delay =>
          processAllRecipients()
        , 500+(Math.random()*1000) # Delay 0.5-1.5 seconds (to not overwhelm server)

    if confirm "Are you sure you want to initiate #{@data.recipients.length} SMSs?"
      processAllRecipients()

  saveSchedule: =>
    @data.numberToSendFrom = @$("#numberToSendFrom").val()
    @data.schedule = @cronUi.getCronString()
    Gooseberry.database.put @data
    .then => @render()

module.exports = QuestionSetView
