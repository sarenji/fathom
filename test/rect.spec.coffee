{Fathom} = require "../fathom"

describe 'Rects', ->
  it 'detects rect-rect collision', ->
    test1 = new Fathom.Entity 10, 10, 20
    test2 = new Fathom.Entity 15, 15, 20
    test3 = new Fathom.Entity 35, 35, 20

    (test1.touchingRect test2).should.be.true
    (test2.touchingRect test1).should.be.true

    (test1.touchingRect test3).should.be.false
    (test3.touchingRect test1).should.be.false

    (test2.touchingRect test3).should.be.true
    (test3.touchingRect test2).should.be.true

  it 'detects point-rect collision', ->
    test = new Fathom.Entity 10, 10, 20

    (test.touchingPoint new Fathom.Point(15, 15)).should.be.true

    # Literally an edge case. HA! HA!
    (test.touchingPoint new Fathom.Point(10, 10)).should.be.true

    (test.touchingPoint new Fathom.Point(9, 9)).should.be.false
