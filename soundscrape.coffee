#!/usr/bin/env coffee

###
 * soundscrape
 * SoundCloud command line downloader
 * Dan Motzenbecker <dan@oxism.com>
 * MIT License
###


http = require 'http'
fs   = require 'fs'

baseUrl    = 'http://soundcloud.com/'
rx         = /bufferTracks\.push\((\{.+?\})\)/g
trackCount = downloaded = 0
argLen     = process.argv.length


scrape = (page, artist, title) ->
  http.get "#{ baseUrl }#{ artist }/#{ title or 'tracks?page=' + page }", (res) ->
    data = ''
    res.on 'data', (chunk) -> data += chunk
    res.on 'end', ->
      while track = rx.exec data
        download parse track[1]
        scrape ++page unless ++trackCount % 10

      unless trackCount
        console.log "\x1b[31m  #{ if title then 'track' else 'artist' } not found  \x1b[0m"
        process.exit 1


parse = (raw) ->
  try
    JSON.parse raw
  catch
    console.log '\x1b[31m  couldn\'t parse the page \x1b[0m'
    process.exit 1


download = (obj) ->
  return unless obj
  pattern = /&\w+;|[^\w\s\(\)\-]/g
  artist  = obj.user.username.replace(pattern, '').trim()
  title   = obj.title.replace(pattern, '').trim()
  console.log "\x1b[33m  fetching: #{ title }  \x1b[0m"
  http.get obj.streamUrl, (res) ->
    http.get res.headers.location, (res) ->
      file = fs.createWriteStream "./#{ artist } - #{ title }.mp3"
      res.on 'data', (chunk) -> file.write chunk
      res.on 'end', ->
        file.end()
        console.log "\x1b[32m  done:     #{ title }  \x1b[0m"
        process.exit 0 if ++downloaded is trackCount


init = ->
  if argLen <= 2
    console.log '\x1b[31m  pass an artist name as the first argument  \x1b[0m'
    process.exit 1

  testFile = '.soundscrape_' + Date.now()
  try
    writeTest = fs.createWriteStream testFile
  catch
    console.log '\x1b[31m  you don\'t have permission to write files here  \x1b[0m'
    process.exit 1

  writeTest.end()
  fs.unlink testFile, (err) -> console.log err if err

  params.artist    = process.argv[2]
  params.trackName = process.argv[3] if argLen > 3
  scrape 1


init()
