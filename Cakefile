fs   = require 'fs'
sys  = require 'sys'
exec = require('child_process').exec;

task 'test', 'test the library', ->
  exec "jasmine-node --coffee spec", (error, stdout, stderr) ->
    if error
      console.err stderr
    else
      console.log stdout