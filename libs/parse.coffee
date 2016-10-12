require 'shelljs/global'
promise = require 'bluebird'
fs = require 'fs'
rlp = require('readline-promise')
_ = require 'lodash'
parser = require 'ua-parser-js'

actions = {
     "logAcceptStart": 0,
     "Declined": 0,
     "validateNumber": 0,
     "OQ": 0,
     "UPQ": 0,
     "Availability": 0,
     "updateCMContactInfo": 0,
     "upsertCMJob": 0,
     "updateCMBio": 0,
     "projectHighlights": 0,
     "Set Project Rate": 0,
     "Finalize Start": 0,
     "Finalize Complete - failedOqWorkflow": 0,
     "Finalize Complete - acceptWorkflow": 0
     "onbeforeunload": 0
}

scanToExtractJson = (region) ->
  inputFileName = './data/syslog.1.gz.singapore_10-06-2016_00-17-13_.log'
  outputFileName = 'data/test.txt'
  exec('gunzip -c ./data/syslog.1.gz.singapore_10-06-2016_00-17-13_.log | grep "cm-accept tracking"  | grep -o -e "{[^}]*}"')
  .to(outputFileName) 
  promise.resolve outputFileName

readToParseJson = (fileName) ->
  fileName= fileName ? 'data/test.txt'
  # console.log 'fileName^^^^^^^^^^^^^', fileName
  output = []
  mapAction = {}
  mapUA = {}
  # pass what you would normally pass to createInterface here
  rlp.createInterface(
    terminal: false
    input: fs.createReadStream(fileName)).each((line) ->
    json = JSON.parse line
    # console.log 'line:', json
    if json.action.indexOf('UAString') > -1
      mapUA[json.cpid] = json.action
    else
      mapAction[json.cpid] = json.action
    return
  ).then((count) ->
    # console.log mapAction
    # console.log mapUA
    output.push(mapAction)
    output.push(mapUA)
    console.log count, output.length
    promise.resolve output
  ).caught (err) ->
    throw err
    promise.reject err

processDropOutData = (data) ->
  # console.log 'data.mapAction', data[0]
  dataArr = []
  actionArr =_.map data[0], (value, key) ->
    json =
      cpid: key
      action: value
    dataArr.push json
    value
  
  _.map actions, (value, key) ->
    itemsCount = _.size (_.find actionArr, (item) ->
      return _.includes item, key
    )
    actions[key] = itemsCount

  console.log 'actions^^^^^^^', dataArr
  data.actions = actions
  data.actionsArr = dataArr
  promise.resolve data

processUAData = (data) ->
  uaArr = []
  actionUaArr =_.map data[1], (value, key) ->
    ua = parser(value)
    uaInfo = 
      cpid: key
      os: ua.os.name
      osVersion: ua.os.version
      browser: ua.browser.name
      browserVersion: ua.browser.version
      vendor: ua.device.vendor ? ''
      type: ua.device.type ? 'desktop'

    uaArr.push(uaInfo)
  _.merge(data.actionsArr, uaArr)
  # console.log 'ua*********', uaArr

  promise.resolve data

fnlist = [
  readToParseJson
  processDropOutData
  processUAData
]

pseries = (list) ->
  p = promise.resolve()
  list.reduce ((pacc, fn) ->
    pacc = pacc.then(fn)
  ), p

module.exports.processActionStats = () ->
  fnlist = [
    readToParseJson
    processDropOutData
  ]
  pseries(fnlist)
  .then (data) ->
    output = {}
    output.actions = data.actions
    console.log 'data********************', data.actionsArr
    promise.resolve output

module.exports.parseUAByAction = (action) ->
  fnlist = [
    readToParseJson
    processDropOutData
    processUAData
  ]
  pseries(fnlist)
  .then (data) ->
    output = {}
    output.actions = data.actions
    console.log 'data********************', data.actionsArr
    promise.resolve output
  
  # # scanToParseJson('si')
  # read('si')
  # .then (data) ->
  #   promise.resolve data
  
  # # exec "pwd", @puts
  