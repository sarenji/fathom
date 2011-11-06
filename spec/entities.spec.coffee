{Fathom} = require "../fathom"

describe 'Entities', ->
  it 'can add and remove an existing entity', ->
    group = new Fathom.Entities

    entity = new Fathom.Entity
    entity.groups = () -> ["stuffs"]
    group.add entity

    expect(group.get(["stuffs"]).length).toEqual 1
    group.removeEntity entity
    expect(group.get(["stuffs"]).length).toEqual 0

