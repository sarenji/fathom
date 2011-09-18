fathom = require "../fathom.js"
Fathom = fathom.Fathom

describe 'Entities', ->
  it 'can add and remove an existing entity', ->
    group = new Fathom.Entities

    test_ent = "entity" : "yep", groups : -> ["stuffs"]
    group.add test_ent

    expect(test_ent.__fathom).toBeDefined()

    expect(group.get(["stuffs"]).length).toEqual 1
    group.removeEntity test_ent
    expect(group.get(["stuffs"]).length).toEqual 0

