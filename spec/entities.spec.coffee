{Fathom} = require "../fathom.js"

describe 'Entities', ->
  it 'has working collision detection', ->
    group = new Fathom.Entities

    class TestEntity extends Fathom.Entity
      constructor: () ->
        super(10, 10, 20)

      groups: () ->
        ["testgroup"]

    test = new TestEntity

    expect(test.touchingPoint x: 15, y: 15).toEqual true

    # Literally an edge case. HA! HA!
    expect(test.touchingPoint x: 10, y: 10).toEqual true
    expect(test.touchingPoint x: 9, y: 9).toEqual false

  it 'can add and remove an existing entity', ->
    group = new Fathom.Entities

    entity = new Fathom.Entity
    entity.groups = () -> ["stuffs"]
    group.add entity

    expect(group.get(["stuffs"]).length).toEqual 1
    group.removeEntity entity
    expect(group.get(["stuffs"]).length).toEqual 0

