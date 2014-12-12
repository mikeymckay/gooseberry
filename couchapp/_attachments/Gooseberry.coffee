Gooseberry = {
  config: {
    database: "gooseberry"
    designDoc: "gooseberry"
  }
}

Backbone.couch_connector.config.db_name = Gooseberry.config.database
Backbone.couch_connector.config.ddoc_name = Gooseberry.config.designDoc
Backbone.couch_connector.config.global_changes = true

Gooseberry.view = (options) ->
  $.couch.db(Gooseberry.config.database).view Gooseberry.config.designDoc+"/"+options.name, options

Gooseberry.save = (options) ->
  $.couch.db(Gooseberry.config.database).saveDoc options.doc, options

Gooseberry.router = new Router()
Backbone.history.start()

Gooseberry.debug = (string) ->
  console.log string
  $("#log").append string + "<br/>"
