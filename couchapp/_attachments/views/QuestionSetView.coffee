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
SweetAlert = require('sweetalert2')

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
        table{
          background-color: lightyellow;
        }
        td,th{
          border: solid 1px black;
          background-color: 

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

    @additionalDataId = "data_#{@questionSet.name()}"

    Gooseberry.database.get @additionalDataId
    .catch (error) =>
      @$el.append "
        <br/>
        <br/>
        <br/>
        <br/>
        <br/>
        <br/>
        <button id='addData'>Add data for question set</button>
      "
      Promise.reject("No additional data")
    .then (@data) =>
      @$el.append "
        <br/>
        <br/>
        <br/>
        <br/>
        <br/>
        <h3>Additional data for #{@questionSet.name()}:</h3>
        <a href='#question_set/#{@additionalDataId}/edit'>Edit Raw Additional Data</a>
        <div id='initiating'></div>
        <div id='recipients'></div>
      "
      if @data.recipients
        @$("#initiating").html "
          <br/>
          <button id='initiate'>Initiate SMS to all recipients now</button>
          <hr/>
          <br/>
          <br/>
          #{
            if @data.schedule
              "
                <div>
                  Currently set to initiate SMS to all recipients #{if @data.schedule then Cronstrue.toString(@data.schedule) else ""} from number: <input id='numberToSendFrom' value='#{@data.numberToSendFrom}'></input>.
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
          <div id='recipients'>
            <div id='recipientTable'></div>

            To update the list of recipients, paste in tab separated data here. The easiest way is just to copy and paste from a spreadsheet or if you already have recipients above, just copy and paste the table and update as needed. The first row of the spreadsheet should be the column names, which should include 'phone number' and 'name'.
            <textarea style='width:100%;height:200px' id='csvRecipients'></textarea>
            <br/>

            <button id='updateRecipients'>Update Recipients</button>
            <hr/>
          </div>
        "

        @cronUi = new CronUI('#schedule', {initial: @data.schedule or '0 9 * * 1'})
        $("#schedule").on "change", (newSchedule) =>
          @$("#saveSchedule").show()


        headers = {}
        _(@data.recipients).each (recipient) =>
          _(Object.keys(recipient)).each (header) =>
            headers[header] = true

        @$("#recipientTable").html "
          <table>
            <thead>
              #{
                _(headers).map (ignore,header) => "<th>#{header}</th>"
                .join("")
              }
            </thead>
            <tbody>
              #{
                _(@data.recipients).map (recipient) =>
                  "
                  <tr>
                    #{
                      console.log recipient
                      _(headers).map (ignore, header) => "<td>#{recipient[header]}</td>"
                      .join("")
                    }
                  </tr>
                  "
                .join("")
              }
            </tbody>
          </table>

        "

  events:
    "click #initiate": "initiate"
    "click #saveSchedule": "saveSchedule"
    "click #updateRecipients": "updateRecipients"
    "click #updateRecipients": "updateRecipients"
    "click #addData": "addDataDoc"

  addDataDoc: =>
    Gooseberry.database.put 
      _id: @additionalDataId
      numberToSendFrom: "20326"
      recipients: [
        {
          "phone number": "+25477777777"
          name: "Sample Name"
          shoe_size: "8.5"
        }
      ]
    .then =>
      @render()



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
       "question_set": @questionSet.name(),
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
    totalNumberOfRecipients = @data.recipients.length
    totalNumberOfMessagesSent = 0
    SweetAlert
      title: "Initiating..."
      text: "Sending messages to #{totalNumberOfRecipients}"
      showCancelButton: true
    .then (result) =>
      if result.dismiss is SweetAlert.DismissReason.cancel
        document.location.reload()
        return
      else
        document.location.reload()

    processAllRecipients = =>
      if @data.recipients.length is 0
        $("#swal2-title").html("Done")
        $("#swal2-content").html("Sent messages to #{totalNumberOfMessagesSent}")
        return
      recipient = @data.recipients.pop()
      totalNumberOfMessagesSent += 1
      $("#swal2-title").html("Initiating #{totalNumberOfMessagesSent}/#{totalNumberOfRecipients}")
      $("#swal2-content").html("Sending to #{recipient.name} - #{recipient["phone number"]}")
      $.post "http://gooseberry.tangerinecentral.org/#{@data.numberToSendFrom}/incoming",
        to: @data.numberToSendFrom
        from: recipient["phone number"]
        text: "START #{@questionSet.name()}"
        plain: true
      .done =>
        processAllRecipients()
      .fail =>
        alert("Initiation failed")

    if confirm "Are you sure you want to initiate #{@data.recipients.length} SMSs?"
      @data.lastInitiatedDate = moment().format("YYYY-MM-DD HH:MM:SS")
      Gooseberry.database.put @data

      processAllRecipients()
      _.delay =>
        processAllRecipients()
      , 500

  saveSchedule: =>
    @data.numberToSendFrom = @$("#numberToSendFrom").val()
    @data.schedule = @cronUi.getCronString()
    Gooseberry.database.put @data
    .then => @render()

module.exports = QuestionSetView
