{Fathom} = require "../fathom"

describe 'Types', ->
  it 'can add and remove an existing entity', ->
    group = new Fathom.Entities

    entity = new Fathom.Entity(0, 0, 0)
    entity.groups = () -> ["stuffs"]
    group.add entity

    (group.get(["stuffs"]).length).should.equal 1
    group.removeEntity entity
    (group.get(["stuffs"]).length).should.equal 0

