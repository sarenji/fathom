{Fathom} = require "../fathom"

describe 'Keys', ->
  it 'has basic keycodes', ->
    Fathom.Key.addKeys()

    (Fathom.Key.A).should.equal 'A'.charCodeAt 0
    (Fathom.Key.D).should.equal 'D'.charCodeAt 0
