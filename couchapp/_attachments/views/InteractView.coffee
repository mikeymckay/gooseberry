$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
_ = require 'underscore'

class InteractView extends Backbone.View
  el: '#content'

  events:
    "click button#send": "send"
    "keyup textarea": "checkforshortcut"

  checkforshortcut: (event) =>
    if (event.keyCode == 13 && event.ctrlKey)
      @send()
      event.stopPropogation

  addSentText: (text) =>
    $("#interactions").append "
      <div class='sent'>#{text}</div>
    "
    $(".latest").removeClass("latest")

  addReceivedText: (text) =>
    $("#interactions").append "
      <div class='received latest'>#{text}</div>
    "
    $("textarea").val("")

  send: =>
    textToSend = $("#textToSend").val()
    if textToSend
      @addSentText(textToSend)
      $.ajax
        url: @target
        data:
          from: "web"
          text: textToSend
          plain: true
        success: (result) =>
          # Split but only at the first :
          [from,text] = result.split(/:(.+)?/)
          @addReceivedText(text)

  render: =>
    @$el.html "
      <textarea id='textToSend'></textarea>
      <button type='button' id='send'>Send</button>
      <div id='interactions'></div>
    "
    $("textarea").val("START #{@name}")
    $("textarea").focus()

module.exports = InteractView
