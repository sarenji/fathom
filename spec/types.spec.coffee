{Types} = require "../fathom"

does_error = (fn) ->
  try
    fn()
  catch error
    return true
  return false

describe 'Number types', ->
  adder = (x, y) ->
    Types.types Types.$number, Types.$number
    x + y

  it 'Typechecks simple types.', ->
    (does_error(() -> adder 1, 2)).should.equal false

  it 'Can fail', ->
    (does_error(() -> adder "a", "b")).should.equal true

describe 'Other simple types', ->
  simple = (str, obj) ->
    Types.types Types.$string, Types.$object
    str[0]
    obj

  it 'Accepts string and object types.', ->
    (does_error(() -> simple "ima string", {ima_object: true})).should.equal false

  it 'Checks string correctly.', ->
    (does_error(() -> simple [], {})).should.equal true

  it 'Checks object correctly.', ->
    (does_error(() -> simple "", "")).should.equal true

describe 'Arrays', ->
  numarray = (arr) ->
    Types.types Types.$array(Types.$number)
    0

  strarray = (arr) ->
    Types.types Types.$array(Types.$string)
    0

  it 'Checks arrays correctly.', -> (does_error(() -> numarray [5])).should.equal false
  it 'Checks arrays correctly.', -> (does_error(() -> strarray ["l"])).should.equal false
  it 'Approves empty arrays.', -> (does_error(() -> strarray [])).should.equal false
  it 'Approves empty arrays.', -> (does_error(() -> numarray [])).should.equal false
  it 'Errors on bad arrays.', -> (does_error(() -> numarray ["f"])).should.equal true
  it 'Errors on bad arrays.', -> (does_error(() -> strarray [5])).should.equal true

describe 'User types', ->
  class Point
    constructor : (@x, @y) ->

  class ColorPoint
    constructor (@x, @y, @color) ->

  addpoint = (pt1, pt2) ->
    Types.types Types.$("Point"), Types.$("Point")
    0

  colorz = (p1, p2) ->
    Types.types Types.$("Point"), Types.$("ColorPoint")
    5

  it 'Checks user types correctly.', -> (does_error(() -> addpoint (new Point(0, 0), new Point(0, 0)))).should.equal false
  it 'Checks user types correctly.', -> (does_error(() -> addpoint (new Point(0, 0), new ColorPoint(0, 0)))).should.equal true
  it 'Checks user types correctly.', -> (does_error(() -> colorz (new Point(0, 0), new ColorPoint(0, 0)))).should.equal false
