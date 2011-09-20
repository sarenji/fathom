#!/usr/bin/env coffee
{exec} = require 'child_process'
fs     = require 'fs'

seen         = {}         # cache of file names
REFRESH_RATE = 500        # in msecs
shouldRun    = true       # if a change in file was detected
canRun       = true       # if tests are running right now, don't run.

runTest = (curr, prev) ->
  if curr.mtime > prev.mtime
    console.log "[autotest] Change in file detected. Rerunning tests...\n"
    shouldRun = true

autotest = ->
  if shouldRun and canRun
    exec 'cake test', (error, stdout, stderr) ->
      console.log(if error then stderr else stdout)
      canRun = true
    shouldRun = canRun = false
  exec 'find . | grep "\\.coffee$"', (error, stdout, stderr) ->
    fileNames = stdout.split('\n')
    for fileName in fileNames
      if fileName not of seen
        seen[fileName] = true
        fs.watchFile fileName, { interval: REFRESH_RATE }, runTest
    setTimeout autotest, REFRESH_RATE

console.log "[autotest] Starting...\n"
autotest()