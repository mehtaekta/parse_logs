path = require 'path'
http = require 'http'
express = require 'express'
bodyParser = require 'body-parser'
cookieParser = require 'cookie-parser'
morgan = require 'morgan'
debug = require('debug') 'parse_log'

# Custom routes
index = require './routes/index'

# Server setup
app = express()
server = http.createServer app

# View engine setup
app.set 'views', path.join(__dirname, 'views')
app.set 'view engine', 'pug'

# setup the logger 
app.use(morgan('combined'))
app.use bodyParser.json()
app.use bodyParser.urlencoded extended: false
app.use cookieParser()

app.use '/public', express.static path.join(__dirname, 'public')

# Define routes
app.use '/', index
app.use '/uaStats/:action', index

# Catch 404 errors
# Forwarded to the error handlers
app.use (req, res, next) ->
  err = new Error 'Not Found'
  err.status = 404
  next err

# Development error handler
# Displays stacktrace to the user
if app.get('env') is 'development'
  app.use (err, req, res, next) ->
    res.status err.status || 500
    res.render 'error',
      message: err.message
      error: err

# Production error handler
# Does not display stacktrace to the user
app.use (err, req, res, next) ->
  res.status err.status || 500
  res.render 'error',
    message: err.message
    error: ''

server.listen process.env.PORT || 9080
module.exports = app
