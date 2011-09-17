fs   = require 'fs'
sys  = require 'sys'
exec = require('child_process').exec;

task 'test', 'test the library', ->
  finishTests = ->
    console.log('\n')
    if errors.length > 0
      console.log(errors.join("\n"))
    else
      console.log("All tests passed!")
    console.log("Total tests: #{tests.length}. Failing tests: #{errors.length}.")
  files  = fs.readdirSync(__dirname + '/tests')
  exts   = [ 'test.js' ]
  tests  = []
  count  = 0
  errors = []

  for file in files
    tests.push(file) if file.substr(-3) is ".js"
  for file in tests
    suite = require("./tests/#{file}")
    for test of suite
      try
        suite[test]()
        process.stdout.write "."
      catch e
        errors.push("#{test}: #{e}")
        process.stdout.write "E"
      finally
        count += 1
        finishTests() if count == tests.length