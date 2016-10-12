express = require 'express'
router = express.Router()
parse = require '../libs/parse'

# GET: /
router.get '/uaStats', (req, res) ->
  action = req.query.key
  parse.parseUAByAction(action)
  .then (data) ->
    console.log 'data&&&&&&&&&&&&&', data
  data = 
    hello: 'world'
  res.json data

router.get '/', (req, res) ->
  parse.processActionStats()
  .then (stats) ->
    res.render 'index/index',
      title: 'cm-accept stats'
      actions: stats.actions

module.exports = router
