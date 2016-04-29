global.$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
BackbonePouch = require 'backbone-pouch'
global._ = require 'underscore'
PouchDB = require 'pouchdb'
PouchDBTools = require './PouchDBTools'

global.Gooseberry = {
  database: new PouchDB("http://localhost:5984/gooseberry")
  logDatabase: new PouchDB("http://localhost:5984/gooseberry-log")
  messageTarget: "http://gooseberry.tangerinecentral.org/22340/incoming"
}

Router = require './Router'

Gooseberry.router = new Router()

Backbone.sync = BackbonePouch.sync
  db: Gooseberry.database
  fetch: 'query'
Backbone.Model.prototype.idAttribute = '_id'

Backbone.history.start()
