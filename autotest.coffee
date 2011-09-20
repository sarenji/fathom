#!/usr/bin/env coffee
{exec} = require 'child_process'
fs     = require 'fs'

seen         = {}         # cache of file names
REFRESH_RATE = 500        # in msecs
running      = false      # if tests are running right now, don't run.
inQueue      = 1          # counter of tests to run.

runTest = (curr, prev) ->
  if curr.mtime > prev.mtime
    console.log "Change in file detected. Rerunning tests..."
    inQueue++

autotest = ->
  if inQueue > 0
    exec 'cake test', (error, stdout, stderr) ->
      console.log stdout
      console.log stderr
    inQueue = 0 # later, we can use a proper queue.
  exec 'find . | grep "\\.coffee$"', (error, stdout, stderr) ->
    fileNames = stdout.split('\n')
    for fileName in fileNames
      if fileName not of seen
        seen[fileName] = true
        fs.watchFile fileName, { interval: REFRESH_RATE }, runTest
    setTimeout autotest, REFRESH_RATE

console.log "autotest starting..."
autotest()