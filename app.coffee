fs = require 'fs'
md = require 'marked'
express = require 'express'
app = express()
socket = require 'socket.io'
exec = require('child_process').exec

filename = 'index.md'

layout = fs.readFileSync('layout.html', 'utf-8')

app.configure ->
  app.use(express.static(__dirname + '/public'))

app.get '/index.md', (req, res)->
  readAndConvert filename, (convertedText)->
    page = layout.replace('{{body}}', convertedText)
    res.setHeader('Content-Type', 'text/html')
    res.setHeader('Content-Length', page.length)
    res.end(page)

readAndConvert = (filename, callbackFn)->
  fs.readFile filename, 'utf-8', (err, body)->
    callbackFn(md(body))

server = app.listen(3000)

io = socket.listen(server)

fs.watchFile filename, (curr, prev)->
  readAndConvert filename, (newBody)->
    io.sockets.emit 'body',
      newBody: newBody

console.log('Listening on port 3000')
exec "open http://localhost:3000/#{filename}"
