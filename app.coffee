fs = require 'fs'
md = require 'marked'
express = require 'express'
path = require 'path'
socket = require 'socket.io'
exec = require('child_process').exec

app = express()
appDir = __dirname

PORT = 4000

filename = process.argv.slice(2)[0]
filename = if filename?
  path.join(process.cwd(), filename)
else
  path.join(appDir, 'README.md')
console.log appDir
console.log __dirname
console.log filename

layout = fs.readFileSync(path.join(appDir, 'layout.html'), 'utf-8')
style = fs.readFileSync(path.join(appDir,'public/markdown.css'), 'utf-8')
layout = layout.replace('{{style}}', style)

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

server = app.listen(PORT)

io = socket.listen(server)

fs.watchFile filename, (curr, prev)->
  readAndConvert filename, (newBody)->
    io.sockets.emit 'body',
      newBody: newBody

console.log("Listening on port #{PORT}")
exec "open http://localhost:#{PORT}/#{filename}"
