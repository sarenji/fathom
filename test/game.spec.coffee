{Fathom} = require "../fathom"

describe 'Game', ->
  it 'has no currentState on create', ->
    game = new Fathom.Game()
    (typeof game.currentState == "undefined").should.be.true