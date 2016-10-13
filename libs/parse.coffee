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

pseries = (list) ->
  p = promise.resolve()
  list.reduce ((pacc, fn) ->
    pacc = pacc.then(fn)
  ), p

scanToExtractJsonLogs = (region) ->
  inputFileName = './data/syslog.1.gz.singapore_10-06-2016_00-17-13_.log'
  outputFileName = 'data/test.txt'
  exec('gunzip -c ./data/syslog.1.gz.singapore_10-06-2016_00-17-13_.log | grep "cm-accept tracking"  | grep -o -e "{[^}]*}"')
  .to(outputFileName) 
  promise.resolve outputFileName

readToParseJson = (fileName) ->
  fileName= fileName ? 'data/test.txt'
  # console.log 'fileName^^^^^^^^^^^^^', fileName
  output = {}
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
    dataArr = []
    _.map mapAction, (value, key) ->
      json =
        cpid: key
        action: value
      dataArr.push json
    output.mapAction = mapAction
    output.mapUA = mapUA
    output.actionUAArr = dataArr
    # output.push(mapAction)
    # output.push(mapUA)
    # console.log count
    promise.resolve output
  ).caught (err) ->
    throw err
    promise.reject err

processDropOutData = (data) ->
  # console.log 'data.mapAction', data[0]
  actionArr =_.map data.mapAction, (value, key) ->
    value
  _.map actions, (value, key) ->
    itemsCount = _.size (_.filter actionArr, (item) ->
      return item.indexOf(key) > -1
    )
    actions[key] = itemsCount

  data.actions = actions
  promise.resolve data

processUAData = (data) ->
  uaArr = []
  actionUaArr =_.map data.mapUA, (value, key) ->
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
  _.merge(data.actionUAArr, uaArr)
  # console.log 'ua*********', uaArr

  promise.resolve data

module.exports.processActionStats = () ->
  fnlist = [
    readToParseJson
    processDropOutData
  ]
  pseries(fnlist)
  .then (data) ->
    output = {}
    output.actions = data.actions
    # console.log 'data********************', data
    promise.resolve output

module.exports.parseUAByAction = (action) ->
  fnlist = [
    readToParseJson
    processDropOutData
    processUAData
  ]
  pseries(fnlist)
  .then (data) ->
    actionUAArr = data.actionUAArr
    actionUAFiltered = _.filter actionUAArr, (actionUA) ->
      if actionUA.action.indexOf(action) > -1
        actionUA
    
    os = []
    actionUAGroupedByOS = _.groupBy actionUAFiltered, 'os'
    _.each actionUAGroupedByOS, (value, key) ->
        os.push(
          key: key
          count: _.size value
        )
      # console.log value, key
    # console.log 'actionUAGroupedByOS********************', os
    promise.resolve output =
      os: os
  