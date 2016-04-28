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
    Gooseberry.database.allDocs
      keys:_(@phoneNumbers).map (phoneNumber) -> "phone_number_#{phoneNumber}"
      include_docs: true
    .catch (error) -> console.error error
    .then (result) ->
      databaseNumbers = {}
      _(result.rows).each (row) ->
        databaseNumbers[row.doc.number] = row.doc.name if row.doc

      tableNumbers = {}
      _($("tr")).each (tableRow) ->
        tableName = $(tableRow).find("td:nth-child(1)").text()
        tableNumber = $(tableRow).find("td:nth-child(2)").text()
        if databaseNumbers[tableNumber] is tableName
          $(tableRow).find("td:nth-child(4)").html "YES"
        else
          $(tableRow).find("td:nth-child(4)").html "NO"
        $(tableRow).find("td:nth-child(3)").html databaseNumbers[tableNumber]


  rowDataForQuestionSetResult: (questionSetResult) =>
    (@questionSet.orderedDataFields()).map (dataField) ->
      questionSetResult.value[dataField]

  rowForQuestionSetResult: (questionSetResult) =>
    if @rowMustInclude? then passesFilter = false else passesFilter = true

    result = questionSetResult.value
    row = "
      <tr id='#{questionSetResult.id}' #{if result.complete isnt true then "class='incomplete'" else ""} >
        #{
          @rowDataForQuestionSetResult(questionSetResult).map (element) =>
            element = element.toUpperCase() if _(element).isString()
            if passesFilter or (_(element).isString() and element.indexOf(@rowMustInclude) > -1)
              passesFilter = true
            "<td>#{element or "-"}</td>"
          .join("")
        }
      </tr>
    "
    if passesFilter
      @numberOfDisplayedRows += 1
      row
    else
      ""
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
