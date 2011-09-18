assert = require "assert"
should = require "should"
fathom = require "../fathom.js"
Fathom = fathom.Fathom

module.exports =
  'test Game' : ->
    game = new Fathom.Game()
    should.not.exist game.currentState
