jasmine = require 'jasmine-node'
coffee  = require 'coffee-script'

task 'test', 'test the library', ->
  # mostly taken from the jasmine cli
  specFolder = "#{__dirname}/spec"
  showColors = true
  isVerbose  = false

  jasmine.loadHelpersInFolder specFolder, /[-_]helper\.(js|coffee)$/
  jasmine.executeSpecsInFolder(
    specFolder,
    (runner, log) ->,
    isVerbose,
    showColors,
    /spec\.(js|coffee)$/i,
    {report: false}
  )
