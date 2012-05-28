{Types} = require "../types"

describe 'Number types', ->
  adder = (x, y) ->
    Types.types(Number, Number)

  it 'Typechecks simple types.', ->
    (-> adder(1, 2)).should.not.throw()

  it 'Can fail', ->
    (-> adder("a", "b")).should.throw()

describe 'Other simple types', ->
  simple = (str, obj) ->
    Types.types(String, Object)

  bool = (b) ->
    Types.types(Boolean)

  fntaker = (fn) ->
    Types.types(Function)

  objtaker = (obj) ->
    Types.types(Object)

  arraytaker = (array) ->
    Types.types(Array)

  it 'Accepts string and object types.', ->
    (-> simple("ima string", {ima_object: true})).should.not.throw()

  it 'Accepts function types.', ->
    (-> fntaker((x) -> x + 1)).should.not.throw()

  it 'Accepts boolean types.', ->
    (-> bool(false)).should.not.throw()

  it "accepts array types", ->
    (-> arraytaker([])).should.not.throw()

  it "accepts array types with more than one element", ->
    (-> arraytaker([1, "c"])).should.not.throw()

  it "accepts object types", ->
    (-> objtaker({})).should.not.throw()

  it 'Checks function correctly.', ->
    (-> fntaker(5)).should.throw()

  it 'Checks string correctly.', ->
    (-> simple([], {})).should.throw()

  it 'Checks object correctly.', ->
    (-> simple("", "")).should.throw()

  it 'Checks booleans correctly.', ->
    (-> bool("ack!")).should.throw()

  it "denies an array as an object", ->
    (-> objtaker([])).should.throw()

  it "checks arrays correctly", ->
    (-> arraytaker({})).should.throw()


describe 'Arrays', ->
  numarray = (arr) ->
    Types.types(Array(Number))

  it 'Checks arrays correctly.', -> (-> numarray([5])).should.not.throw()
  it 'Approves empty arrays.', -> (-> numarray([])).should.not.throw()
  it 'Errors on bad arrays.', -> (-> numarray(["f"])).should.throw()
  it 'Errors on non-arrays.', -> (-> numarray("f")).should.throw()

describe 'User types', ->
  class Point
    constructor: (@x, @y) ->

  class ColorPoint
    constructor: (@x, @y, @color) ->

  addpoint = (pt1, pt2) ->
    Types.types(Point, Point)

  colorz = (p1, p2) ->
    Types.types(Point, ColorPoint)

  it 'Checks user types correctly.', -> (-> addpoint(new Point(0, 0), new Point(0, 0))).should.not.throw()
  it 'Checks user types correctly.', -> (-> addpoint(new Point(0, 0), new ColorPoint(0, 0))).should.throw()
  it 'Checks user types correctly.', -> (-> colorz(new Point(0, 0), new ColorPoint(0, 0))).should.not.throw()

describe 'User types with subtype relations', ->
  class Point
    constructor : (@x, @y) ->

  class SuperPoint extends Point
    constructor : (@x, @y, @z) ->

  class HyperPoint extends SuperPoint
    constructor : (@x, @y, @z, @q) ->

  general = (p1) -> Types.types(Point)
  specific = (p1) -> Types.types(SuperPoint)

  it 'General allowed for general.', -> (-> general(new Point(0, 0))).should.not.throw()
  it 'Specific allowed for general.', -> (-> general(new SuperPoint(0, 0, 0))).should.not.throw()
  it 'Specific allowed for specific.', -> (-> specific(new SuperPoint(0, 0, 0))).should.not.throw()
  it 'General *not* allowed for specific.', -> (-> specific(new Point(0, 0, 0))).should.throw()
  it 'Ascends the proto chain convincingly.', -> (-> general(new HyperPoint(0, 0, 0, 0))).should.not.throw()

describe 'Arrays and subtypes', ->
  class Point
    constructor : (@x, @y) ->

  class SuperPoint extends Point
    constructor : (@x, @y, @z) ->

  general = (p) -> Types.types(Array(Point))
  specific = (p) -> Types.types(Array(SuperPoint))

  it 'General allowed for general.', -> (-> general([new Point(0, 0)])).should.not.throw()
  it 'Specific allowed for general.', -> (-> general([new SuperPoint(0, 0, 0)])).should.not.throw()
  it 'Specific allowed for specific.', -> (-> specific([new SuperPoint(0, 0, 0)])).should.not.throw()
  it 'General *not* allowed for specific.', -> (-> specific([new Point(0, 0, 0)])).should.throw()

describe 'Optional types', ->
  optionaltastic = (a, b, c=0, d=0) ->
    Types.types(Number, Number, Types.Optional(Number), Types.Optional(Number))

  it 'does not validate if max cardinality is exceeded', -> (-> optionaltastic(0, 0, 0, 0, 0)).should.throw()
  it 'validates if all optional values are passed', -> (-> optionaltastic(0, 0, 0, 0)).should.not.throw()
  it 'validates if some optional values are passed', -> (-> optionaltastic(0, 0, 0)).should.not.throw()
  it 'validates if no optional values are passed', -> (-> optionaltastic(0, 0)).should.not.throw()
  it 'throws if too few arguments', -> (-> optionaltastic(0)).should.throw()
  it 'throws if too many arguments', -> (-> optionaltastic(0, 0, 0, 0, 0)).should.throw()

describe 'Argument list length', ->
  innocentFunction = (a, b, c) ->
    Types.types(Number, Number, Number)

  it 'validates argument length.', -> (-> innocentFunction(1,1,1)).should.not.throw()
  it 'does not validate if exceeding argument cardinality constraint', -> (-> innocentFunction(1,1,1,4)).should.throw()
  it 'does not validate if under argument cardinality constraint', -> (-> innocentFunction(1,1)).should.throw()
