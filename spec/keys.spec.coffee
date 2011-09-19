{Fathom} = require "../fathom.js"

describe 'Keys', ->
  it 'has basic keycodes', ->
    Fathom.Key.addKeys()

    expect(Fathom.Key.A).toEqual 65
    expect(Fathom.Key.D).toEqual 68
