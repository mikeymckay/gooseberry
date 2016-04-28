$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
_ = require 'underscore'

DataTables = require('datatables.net')(window,$)
moment = require 'moment'

FileSaver = require 'filesaverjs'

QuestionSet = require '../models/QuestionSet'

class ResultsView extends Backbone.View
  render: () =>
    @$el.html "
      <style>
        tr {
          text-align:center;
        }
      </style>
      <button id='csv'>Download as CSV</button>
    "
    @renderTableStructure()
    @renderTableContents()


  renderTableStructure: =>
    @$el.append "
      <table id='results'>
        <thead>
          #{
            if @useAllFields
              @allFields = _(@results).chain().map (result) ->
                _(result.value).keys()
              .flatten().uniq().sort().value()

              _(@allFields).map (field) ->
                "<th>#{field}</th>"
              .join("")
            else
              _(@questionSet.orderedDataFields()).map (header) ->
                "<th>#{header}</th>"
              .join("")
          }
        </thead>
        <tbody>
        </tbody>
      </table>
    "

  renderTableContents: () =>
    @numberOfDisplayedRows = 0
    @phoneNumbers = []
    @$el.find("tbody").html(
      _(@results).map (result) =>
        @rowForQuestionSetResult(result)
      .join("")
    )

  rowDataForQuestionSetResult: (questionSetResult) =>
    if @useAllFields
      (@allFields).map (dataField) ->
        questionSetResult.value[dataField]
    else
      (@questionSet.orderedDataFields()).map (dataField) ->
        questionSetResult.value[dataField]

  rowForQuestionSetResult: (questionSetResult) =>
    result = questionSetResult.value
    @numberOfDisplayedRows += 1
    "
      <tr id='#{questionSetResult.id}' #{if result.complete isnt true then "class='incomplete'" else ""} >
        #{
          @rowDataForQuestionSetResult(questionSetResult).map (element) =>
            element = element.toUpperCase() if _(element).isString()
            "<td>#{element or "-"}</td>"
          .join("")
        }
      </tr>
    "
  csv: =>
    csvString = ""
    _($("table#results thead tr")).each (tr) ->
      csvString += _($(tr).find("th")).map (th) ->
        "\"#{th.innerHTML}\""
      .join(",")

    _($("table#results tbody tr")).each (tr) ->
      csvString += _($(tr).find("td")).map (td) ->
        "\"#{td.innerHTML}\""
      .join(",")
      csvString += "\n"

    blob = new Blob([csvString], {type: "text/plain;charset=utf-8"})
    fileName = @csvName || "output.csv"
    FileSaver.saveAs(blob, fileName)

  events:
    "click button#csv": "csv"

module.exports = ResultsView
