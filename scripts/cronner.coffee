CronParser = require 'cron-parser'
moment = require 'moment'
PouchDB = require 'pouchdb'
_ = require 'underscore'
request = require 'request'

howOftenInMillisecondsIsThisRun = 5*60*1000 # 5 minutes

database = new PouchDB("http://localhost:5984/gooseberry")
#gooseberryIncomingURL = "http://gooseberry.tangerinecentral.org/20326/incoming"
gooseberryIncomingURL = "http://localhost:3000"

database.allDocs
  startkey: "data_"
  endkey: "data_\ufff0"
  include_docs: true
.then (result) ->
  _(result.rows).each (row) ->
    if row.doc.schedule
      processQuestionSetSchedule(row.doc)

processQuestionSetSchedule = (dataForQuestionSet) =>
  cronJob = CronParser.parseExpression(dataForQuestionSet.schedule)

  millisecondsUntilNextRun = moment(cronJob.next().toDate()).diff(moment())

  questionSetName = dataForQuestionSet._id.replace(/^data_/,"")

  if millisecondsUntilNextRun < howOftenInMillisecondsIsThisRun
    console.log "Running #{questionSetName} in #{Math.round millisecondsUntilNextRun/1000} seconds"
    _.delay =>
      if dataForQuestionSet.recipients
        initiateQuestionSet(dataForQuestionSet)
    , millisecondsUntilNextRun
  else
    console.log "Next run for #{questionSetName} in #{Math.round millisecondsUntilNextRun/1000} seconds, will be handled later."

initiateQuestionSet = (dataForQuestionSet) =>
  questionSet = dataForQuestionSet._id.replace(/^data_/,"")
  numberToSendFrom = dataForQuestionSet.numberToSendFrom
  recipients = dataForQuestionSet.recipients

  processAllRecipients = =>
    return if recipients.length is 0
    recipient = recipients.pop()
    request.post gooseberryIncomingURL,
      form:
        to: numberToSendFrom
        from: cleanPhoneNumber(recipient["Phone number"])
        text: "START #{questionSet}"
        plain: true
    .on "response", =>
      _.delay =>
        processAllRecipients()
      , 500+(Math.Random()*1000) # Delay 0.5-1.5 seconds (to not overwhelm server)

  processAllRecipients()

cleanPhoneNumber = (phoneNumber) =>
  phoneNumber
  .toString()
  .replace(/^7/,"+2547")
  .replace(/^07/,"+2547")
