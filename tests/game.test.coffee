assert = require "assert"
should = require "should"
fathom = require "../fathom.js"

module.exports =
  'test Game' : ->
    game = new fathom.Game()
    should.not.exist game.currentState
