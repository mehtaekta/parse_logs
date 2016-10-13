express = require 'express'
router = express.Router()
parse = require '../libs/parse'
pug = require 'pug'
path = require 'path'

# GET: /
router.get '/uaStats', (req, res) ->
  action = req.query.key
  parse.parseUAByAction(action)
  .then (data) ->
    console.log 'data&&&&&&&&&&&&&', data
    renderedTemplate = pug.renderFile path.join(__dirname, '../views/index/uaStats.pug'), data
    res.json renderedTemplate

router.get '/', (req, res) ->
  parse.processActionStats()
  .then (stats) ->
    res.render 'index/index',
      title: 'cm-accept stats'
      actions: stats.actions

module.exports = router
