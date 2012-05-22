{Types} = require "../fathom"

does_error = (fn) ->
  try
    fn()
  catch error
    console.log error
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

  it 'Checks user types correctly.', -> (does_error(() -> addpoint(new Point(0, 0), new Point(0, 0)))).should.equal false
  it 'Checks user types correctly.', -> (does_error(() -> addpoint(new Point(0, 0), new ColorPoint(0, 0)))).should.equal true
  it 'Checks user types correctly.', -> (does_error(() -> colorz(new Point(0, 0), new ColorPoint(0, 0)))).should.equal false

describe 'User types with subtype relations', ->
  class Point
    constructor : (@x, @y) ->

  class SuperPoint extends Point
    constructor (@x, @y, @z) ->

  class HyperPoint extends SuperPoint
    constructor (@x, @y, @z, @q) ->

  general = (p1) -> Types.types Types.$("Point")
  specific = (p1) -> Types.types Types.$("SuperPoint")

  it 'General allowed for general.', -> (does_error(() -> general(new Point(0, 0)))).should.equal false
  it 'Specific allowed for general.', -> (does_error(() -> general(new SuperPoint(0, 0, 0)))).should.equal false
  it 'Specific allowed for specific.', -> (does_error(() -> specific(new SuperPoint(0, 0, 0)))).should.equal false
  it 'General *not* allowed for specific.', -> (does_error(() -> specific(new Point(0, 0, 0)))).should.equal true
  it 'Ascends the proto chain convincingly.', -> (does_error(() -> general(new HyperPoint(0, 0, 0, 0)))).should.equal false

describe 'Arrays and subtypes', ->
  class Point
    constructor : (@x, @y) ->

  class SuperPoint extends Point
    constructor (@x, @y, @z) ->

  general = (p) -> Types.types Types.$array(Types.$("Point"))
  specific = (p) -> Types.types Types.$array(Types.$("SuperPoint"))

  it 'General allowed for general.', -> (does_error(() -> general([new Point(0, 0)]))).should.equal false
  it 'Specific allowed for general.', -> (does_error(() -> general([new SuperPoint(0, 0, 0)]))).should.equal false
  it 'Specific allowed for specific.', -> (does_error(() -> specific([new SuperPoint(0, 0, 0)]))).should.equal false
  it 'General *not* allowed for specific.', -> (does_error(() -> specific([new Point(0, 0, 0)]))).should.equal true

describe 'Argument list length', ->
  innocentFunction = (a, b, c) ->
    Types.types Types.$number, Types.$number, Types.$number

    a+b+c

  it 'Validates argument length.', -> (does_error(() -> innocentFunction(1,1,1))).should.equal false
  it 'Validates incorrect argument length.', -> (does_error(() -> innocentFunction(1,1,1,4))).should.equal true
  it 'Validates incorrect argument length.', -> (does_error(() -> innocentFunction(1,1))).should.equal true
