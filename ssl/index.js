var express = require('express')
var fs = require('fs')
var https = require('https')
var app = express()
var http = require('http')

app.get('/', function (req, res) {
  res.send('hello world')
})

const test = process.env.TEST;

if (test == 'http') {
  http.createServer({
    key: fs.readFileSync('server.key'),
    cert: fs.readFileSync('server.cert')
  }, app)
  .listen(3000, function () {
    console.log('Example app listening on port 3000! Go to http://195.251.251.27:3000/')
  })
} else {
  https.createServer({
    key: fs.readFileSync('server.key'),
    cert: fs.readFileSync('server.cert')
  }, app)
  .listen(3000, function () {
    console.log('Example app listening on port 3000! Go to https://195.251.251.27:3000/')
  })
}
