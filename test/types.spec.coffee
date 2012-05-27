{Types} = require "../types"

describe 'Number types', ->
  adder = (x, y) ->
    Types.types Types.$number, Types.$number
    x + y

  it 'Typechecks simple types.', ->
    (() -> adder 1, 2).should.not.throw()

  it 'Can fail', ->
    (() -> adder "a", "b").should.throw()

describe 'Other simple types', ->
  simple = (str, obj) ->
    Types.types Types.$string, Types.$object
    str[0]
    obj

  fntaker = (fn) ->
    Types.types Types.$function
    fn(5)

  it 'Accepts string and object types.', ->
    (() -> simple "ima string", {ima_object: true}).should.not.throw()

  it 'Accepts function types.', ->
    (() -> fntaker((x) -> x + 1)).should.not.throw()

  it 'Checks function correctly.', ->
    (() -> fntaker 5).should.throw()

  it 'Checks string correctly.', ->
    (() -> simple [], {}).should.throw()

  it 'Checks object correctly.', ->
    (() -> simple "", "").should.throw()

describe 'Arrays', ->
  numarray = (arr) ->
    Types.types Types.$array(Types.$number)
    0

  strarray = (arr) ->
    Types.types Types.$array(Types.$string)
    0

  it 'Checks arrays correctly.', -> (() -> numarray [5]).should.not.throw()
  it 'Checks arrays correctly.', -> (() -> strarray ["l"]).should.not.throw()
  it 'Approves empty arrays.', -> (() -> strarray []).should.not.throw()
  it 'Approves empty arrays.', -> (() -> numarray []).should.not.throw()
  it 'Errors on bad arrays.', -> (() -> numarray ["f"]).should.throw()
  it 'Errors on bad arrays.', -> (() -> strarray [5]).should.throw()

describe 'User types', ->
  class Point
    constructor: (@x, @y) ->

  class ColorPoint
    constructor: (@x, @y, @color) ->

  addpoint = (pt1, pt2) ->
    Types.types Types.$("Point"), Types.$("Point")
    0

  colorz = (p1, p2) ->
    Types.types Types.$("Point"), Types.$("ColorPoint")
    5

  it 'Checks user types correctly.', -> (() -> addpoint(new Point(0, 0), new Point(0, 0))).should.not.throw()
  it 'Checks user types correctly.', -> (() -> addpoint(new Point(0, 0), new ColorPoint(0, 0))).should.throw()
  it 'Checks user types correctly.', -> (() -> colorz(new Point(0, 0), new ColorPoint(0, 0))).should.not.throw()

describe 'Optional types', ->
  optionaltastic = (a, b, c=0, d=0) ->
    Types.types Types.$number, Types.$number, Types.$optional(Types.$number), Types.$optional(Types.$number)

  it 'validates a correctly called optional function', -> (() -> optionaltastic(0, 0, 0, 0)).should.not.throw()
  it 'validates a correctly called optional function', -> (() -> optionaltastic(0, 0, 0)).should.not.throw()
  it 'validates a correctly called optional function', -> (() -> optionaltastic(0, 0)).should.not.throw()

  it 'throws for too few arguments', -> (() -> optionaltastic(0)).should.throw()
  it 'throws for too many arguments', -> (() -> optionaltastic(0, 0, 0, 0, 0)).should.throw()

describe 'User types with subtype relations', ->
  class Point
    constructor : (@x, @y) ->

  class SuperPoint extends Point
    constructor (@x, @y, @z) ->

  class HyperPoint extends SuperPoint
    constructor (@x, @y, @z, @q) ->

  general = (p1) -> Types.types Types.$("Point")
  specific = (p1) -> Types.types Types.$("SuperPoint")

  it 'General allowed for general.', -> (() -> general(new Point(0, 0))).should.not.throw()
  it 'Specific allowed for general.', -> (() -> general(new SuperPoint(0, 0, 0))).should.not.throw()
  it 'Specific allowed for specific.', -> (() -> specific(new SuperPoint(0, 0, 0))).should.not.throw()
  it 'General *not* allowed for specific.', -> (() -> specific(new Point(0, 0, 0))).should.throw()
  it 'Ascends the proto chain convincingly.', -> (() -> general(new HyperPoint(0, 0, 0, 0))).should.not.throw()

describe 'Arrays and subtypes', ->
  class Point
    constructor : (@x, @y) ->

  class SuperPoint extends Point
    constructor (@x, @y, @z) ->

  general = (p) -> Types.types Types.$array(Types.$("Point"))
  specific = (p) -> Types.types Types.$array(Types.$("SuperPoint"))

  it 'General allowed for general.', -> (() -> general([new Point(0, 0)])).should.not.throw()
  it 'Specific allowed for general.', -> (() -> general([new SuperPoint(0, 0, 0)])).should.not.throw()
  it 'Specific allowed for specific.', -> (() -> specific([new SuperPoint(0, 0, 0)])).should.not.throw()
  it 'General *not* allowed for specific.', -> (() -> specific([new Point(0, 0, 0)])).should.throw()

describe 'Argument list length', ->
  innocentFunction = (a, b, c) ->
    Types.types Types.$number, Types.$number, Types.$number

    a+b+c

  it 'Validates argument length.', -> (() -> innocentFunction(1,1,1)).should.not.throw()
  it 'Validates incorrect argument length.', -> (() -> innocentFunction(1,1,1,4)).should.throw()
  it 'Validates incorrect argument length.', -> (() -> innocentFunction(1,1)).should.throw()
