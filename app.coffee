fs = require 'fs'
md = require 'marked'
express = require 'express'
app = express()
socket = require 'socket.io'
exec = require('child_process').exec

args = process.argv.slice(2)[0]
if args?
  filename = args
else
  filename = 'README.md'


layout = fs.readFileSync('layout.html', 'utf-8')

app.configure ->
  app.use(express.static(__dirname + '/public'))
  app.use(express.favicon(__dirname + '/public/favicon.ico'))

app.get "/#{filename}", (req, res)->
  readAndConvert filename, (convertedText)->
    layout = layout.replace('{{filename}}', filename)
    if convertedText?
      page = layout.replace('{{body}}', convertedText)
      res.setHeader('Content-Type', 'text/html')
      res.setHeader('Content-Length', page.length)
      res.end(page)
    else
      page = layout.replace('{{body}}', "File #{filename} not found.")
      res.setHeader('Content-Type', 'text/html')
      res.setHeader('Content-Length', page.length)
      res.end(page)

readAndConvert = (filename, callbackFn)->
  fs.readFile filename, 'utf-8', (err, body)->
    if err?
      callbackFn(null)
    else
      callbackFn(md(body))

server = app.listen(3000)

io = socket.listen(server)

fs.watchFile filename, (curr, prev)->
  readAndConvert filename, (newBody)->
    io.sockets.emit 'body',
      newBody: newBody

console.log('Listening on port 3000')
exec "open http://localhost:3000/#{filename}"
