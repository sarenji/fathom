jasmine = require 'jasmine-node'
coffee  = require 'coffee-script'
growl   = require 'growl'
notify  = require 'notify-send'

task 'test', 'test the library', ->
  # mostly taken from the jasmine cli
  specFolder = "#{__dirname}/spec"
  showColors = true
  isVerbose  = false
  title      = "Fathom tests"

  jasmine.loadHelpersInFolder specFolder, /[-_]helper\.(js|coffee)$/
  jasmine.executeSpecsInFolder(
    specFolder,
    (runner, log) ->
      results = runner.results()
      message = "#{results.passedCount}/#{results.totalCount} tests passed."
      urgency = 'low'
      if results.failedCount > 0
        message = "#{results.failedCount} tests failed! #{message}"
        urgency = 'critical'
      growl.notify message, title: title, sticky: urgency == 'critical'
      notify[urgency].category(title).notify message
    ,
    isVerbose,
    showColors,
    /spec\.(js|coffee)$/i,
    {report: false}
  )
