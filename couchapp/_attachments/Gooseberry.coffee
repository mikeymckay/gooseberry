Gooseberry = {
  config:
    database: "gooseberry"
    logDatabase: "gooseberry-log"

  view: (options) ->
    $.couch.db(Gooseberry.config.database).view Gooseberry.config.designDoc+"/"+options.name, options

  viewLogDB: (options) ->
    $.couch.db(Gooseberry.config.logDatabase).view Gooseberry.config.designDoc+"/"+options.name, options
}


Gooseberry.save = (options) ->
  $.couch.db(Gooseberry.config.database).saveDoc options.doc, options


$.couch.db(Gooseberry.config.database).openDoc "config",
  success: (result) ->

    Gooseberry.config = _(Gooseberry.config).extend result
    Gooseberry.router = new Router()

    Backbone.couch_connector.config.db_name = Gooseberry.config.database
    Backbone.couch_connector.config.ddoc_name = Gooseberry.config.designDoc
#    Backbone.couch_connector.config.global_changes = true

    Backbone.history.start()

Gooseberry.debug = (string) ->
  console.log string
  $("#log").append string + "<br/>"
