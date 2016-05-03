request = require 'request'
_ = require 'underscore'

sampleMessages = [
  "Start TUSOMETEACHER"
  "Mike McKay"
  "2"
  "Zone"
  "School Name"
  "MR"
  "Role"
  "Washoe"
  "M"
  "Y"
  "Y"
  "Y"
]

numberOfIterations = 1

console.log new Date().toString().replace(/ G.*/,"").replace(/.*2016 /,"")

startTimes = {}

sendNextMessage = (sampleMessageIndex, sessionIndex) ->

  startTimes[sessionIndex] = new Date().getTime() if sampleMessageIndex is 0

  currentTime = new Date().toString().replace(/ G.*/,"").replace(/.*2016 /,"")
  url = "http://localhost:9393/incoming?from=web#{sessionIndex}&to=22340&date=#{currentTime}&id=barz&linkId=foo&text=#{sampleMessages[sampleMessageIndex]}"
  #console.log "REQUEST: #{sessionIndex}: #{sampleMessages[sampleMessageIndex]}"
  #startTime = new Date().getTime()
  request url, (error, response, body) ->
    #console.log "Response took: #{new Date().getTime() - startTime}"
    #console.log body
    if sampleMessageIndex is sampleMessages.length
      console.log "Session complete. Took: #{new Date().getTime() - startTimes[sessionIndex]} milliseconds"
      if sessionIndex == numberOfIterations
        console.log "#{numberOfIterations} iterations complete. Took: #{new Date().getTime() - startTimes[1]} milliseconds"
    else
      sendNextMessage(sampleMessageIndex+1, sessionIndex)

_([1..numberOfIterations]).each (sessionIndex) ->
  sendNextMessage(0,sessionIndex)

