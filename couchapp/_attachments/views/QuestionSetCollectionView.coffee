_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
QuestionSet = require '../models/QuestionSet'
QuestionSetCollection = require '../models/QuestionSetCollection'

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
    target = Gooseberry.messageTarget
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
    @questionSets = new QuestionSetCollection()
    @questionSets.fetch
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
               @questionSets.map (questionSet) ->
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
        @questionSets.each (questionSet) ->
          questionSet.resultCount
            success: (count) ->
              $("tr[data-name='#{questionSet.name()}'] td.number-of-results").html count

module.exports = QuestionSetCollectionView
