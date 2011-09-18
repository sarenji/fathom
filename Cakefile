fs   = require 'fs'
sys  = require 'sys'
exec = require('child_process').exec;

task 'test', 'test the library', ->
  # print out the final testing results
  finishTests = ->
    console.log('\n')
    if errors.length > 0
      console.log(errors.join("\n"))
    else
      console.log("All tests passed!")
    console.log("Total tests: #{total}. Failing tests: #{errors.length}.")

  files  = fs.readdirSync(__dirname + '/tests')
  exts   = [ 'test.js' ]
  tests  = []
  count  = 0
  errors = []
  suites = []
  total  = 0

  # find all files in the tests/ directory ending in .js
  for file in files
    tests.push(file) if file.substr(-3) is ".js"
  
  # get each suites inside a test file
  # increment the total number of tests
  for file in tests
    suite = require("./tests/#{file}")
    total += 1 for test of suite
    suites.push(suite)

  # iterate through all suites and run each test.
  for suite in suites
    for test of suite
      try
        suite[test]()
        process.stdout.write "."
      catch e
        errors.push("#{test}: #{e}")
        process.stdout.write "E"
      finally
        count += 1
        finishTests() if count == total