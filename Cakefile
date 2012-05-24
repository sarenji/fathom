{exec} = require 'child_process'
{print} = require 'util'

task 'test', 'Run tests.', ->
  exec 'coffee -c *.coffee spec/*.coffee && mocha spec/*.js --require should', (err, stdout, stderr) ->
    print stdout if stdout?
    print stderr if stderr?
