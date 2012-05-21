{Types} = require "../fathom"

does_error = (fn) ->
  try
    fn()
  catch error
    console.log error
    return true
  return false

describe 'Types', ->
  adder = (x, y) ->
    Types.types Types.$number, Types.$number
    x + y

  it 'Typechecks some basic stuff', ->
    (does_error(() -> adder "a", "b")).should.equal true
  it 'Can fail.', ->
    (does_error(() -> adder 1, 2)).should.equal false
