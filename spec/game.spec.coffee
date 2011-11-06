{Fathom} = require "../fathom"

describe 'Game', ->
  it 'has no currentState on create', ->
    game = new Fathom.Game()
    expect(game.currentState).toBeUndefined()
