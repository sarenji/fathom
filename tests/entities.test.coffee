assert = require "assert"
should = require "should"
fathom = require "../fathom.js"
Fathom = fathom.Fathom

module.exports =
  'test Entities' : ->
    group = new Fathom.Entities

    test_ent = "entity" : "yep"
    group.add test_ent, ["stuffs"]

    test_ent.__fathom.should.ok

    (group.get ["stuffs"]).length.should.equal 1
    group.removeEntity test_ent
    (group.get ["stuffs"]).should.be.empty

