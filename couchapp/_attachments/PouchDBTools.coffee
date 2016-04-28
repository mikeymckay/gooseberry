_ = require 'underscore'
#CoffeeScript = require 'coffee-script' - this is loaded in index.html

PouchDBTools = {}
PouchDBTools.addOrUpdateDesignDoc = (options) ->
  database = options.database
  designDoc = options.designDoc
  name = designDoc._id.replace(/^_design\//,"")

  database.get "_design/#{name}", (error,result) ->
    # Check if it already exists and is the same
    if result?.views?[name]?.map is designDoc.views[name].map
      options?.success?()
    else
      console.log "Updating design doc for #{name}"
      if result? and result._rev
        designDoc._rev = result._rev
      database.put(designDoc).then ->
        options?.success?()
      .catch (error) ->
        console.log "Error. Current Result:"
        console.log result

        console.log error
        console.log "^^^^^ Error updating designDoc for #{name}:"
        console.log designDoc
          
PouchDBTools.createDesignDoc = (name, mapFunction) ->
  # Allows coffeescript string to get compiled into functions. For extra dynamic-ness - use heredocs """ (see ResultCollection)
  if not _.isFunction(mapFunction)
    mapFunction = CoffeeScript.compile(mapFunction, bare:on)
  else
    mapFunction = mapFunction.toString()

  ddoc = {
    _id: '_design/' + name,
    views: {}
  }
  ddoc.views[name] = {
    map: mapFunction
  }
  return ddoc

module.exports = PouchDBTools
