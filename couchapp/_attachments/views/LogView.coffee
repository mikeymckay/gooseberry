$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
_ = require 'underscore'

class LogView extends Backbone.View
  el: '#content'

  addText: (message) =>
    $("#interactions").append "
      <div class='#{message.value[0]}'><div style='float:right;font-size:50%'>#{message.key[1]}</div>#{message.value[1]}</div>
    "

  render: =>
    @$el.html "
      <h1>#{@number}</h1>
      <div id='interactions'></div>
    "

    _(@logData).each (message) =>
      @addText(message)

module.exports = LogView
