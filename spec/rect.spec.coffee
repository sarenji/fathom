{Fathom} = require "../fathom"

describe 'Rects', ->
  it 'detects rect-rect collision', ->
    test1 = new Fathom.Entity 10, 10, 20
    test2 = new Fathom.Entity 15, 15, 20
    test3 = new Fathom.Entity 35, 35, 20

    expect(test1.touchingRect test2).toEqual true
    expect(test2.touchingRect test1).toEqual true

    expect(test1.touchingRect test3).toEqual false
    expect(test3.touchingRect test1).toEqual false

    expect(test2.touchingRect test3).toEqual true
    expect(test3.touchingRect test2).toEqual true

  it 'detects point-rect collision', ->
    test = new Fathom.Entity 10, 10, 20

    expect(test.touchingPoint x: 15, y: 15).toEqual true

    # Literally an edge case. HA! HA!
    expect(test.touchingPoint x: 10, y: 10).toEqual true

    expect(test.touchingPoint x: 9, y: 9).toEqual false
