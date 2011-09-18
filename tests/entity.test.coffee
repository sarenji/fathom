assert = require "assert"
should = require "should"
fathom = require "../fathom.js"
Fathom = fathom.Fathom

module.exports =
  'test Entity#emit on bogus event' : ->
    entity = new Fathom.Entity
    entity.emit('bogus event') # should not error
    true.should.be.ok
  'test Entity#emit on real event without args' : ->
    entity = new Fathom.Entity
    entity.on 'some event', ->
      @stuff_got_done = true
    entity.emit('some event')
    should.ok entity.stuff_got_done
  'test Entity#emit on real event with args' : ->
    entity = new Fathom.Entity
    entity.on 'some event', (number) ->
      @number = number
    entity.emit('some event', 42)
    entity.number.should.equal 42