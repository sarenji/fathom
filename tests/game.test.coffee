assert = require "assert"
should = require "should"
fathom = require "../index.js"

module.exports =
  'test Game' : ->
    game = new fathom.Game()
    should.not.exist game.currentState
