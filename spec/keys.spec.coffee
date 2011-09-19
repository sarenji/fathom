{Fathom} = require "../fathom.js"

describe 'Keys', ->
  it 'has basic keycodes', ->
    Fathom.Key.addKeys()

    expect(Fathom.Key.A).toEqual 'A'.charCodeAt 0
    expect(Fathom.Key.D).toEqual 'D'.charCodeAt 0
