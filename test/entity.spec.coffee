{Fathom} = require "../fathom"

describe 'Entity', ->
  describe '#on', ->
    it 'should add a callback for new events', ->
      entity = new Fathom.Entity
      event  = 'some event'

      (typeof entity.__fathom.events[event] == "undefined").should.be.true
      entity.on event, -> @david_rules = true
      (entity.__fathom.events[event].length).should.equal 1

    it 'should add callbacks to existing events', ->
      entity = new Fathom.Entity
      event  = 'some event'
      entity.on event, -> @david_rules = true
      entity.on event, -> @grant_too = true

      (entity.__fathom.events[event].length).should.equal 2

    it 'should not add the same callback to the same event', ->
      entity = new Fathom.Entity
      event  = 'some event'
      david  = -> @david_rules = true
      entity.on event, david
      entity.on event, david

      (entity.__fathom.events[event].length).should.equal 1

    it 'can add the same callback to two different events', ->
      entity = new Fathom.Entity
      david  = -> @david_rules = true
      entity.on 'some event',    -> david
      entity.on 'another event', -> david

      (entity.__fathom.events['some event'].length).should.equal 1
      (entity.__fathom.events['another event'].length).should.equal 1

  describe '#off', ->
    describe 'when providing a specific callback', ->
      entity = new Fathom.Entity
      david  = -> @david_rules = true
      grant  = -> @grant_too = true
      event  = 'some event'
      entity.on event, david
      entity.on event, grant

      it 'should remove the event', ->
        entity.off event, david
        (entity.__fathom.events[event].length).should.equal 1
        (entity.__fathom.events[event][0]).should.eql grant

      it 'should remove empty arrays to save memory', ->
        entity.off event, grant
        (typeof entity.__fathom.events[event] == "undefined").should.be.true

    describe 'when only providing the event name', ->
      entity = new Fathom.Entity
      david  = -> @david_rules = true
      grant  = -> @grant_too = true
      event  = 'some event'
      entity.on event, david
      entity.on event, grant

      it 'should remove all attached callbacks', ->
        entity.off event
        (typeof entity.__fathom.events[event] == "undefined").should.be.true

    describe 'on a bogus event', ->
      describe 'when providing a specific callback', ->
        entity = new Fathom.Entity
        it 'should fail noisily', ->
          (-> entity.off('bogus event', ->)).should.throw()

      describe 'when only providing the event name', ->
        entity = new Fathom.Entity
        it 'should fail noisily', ->
          (-> entity.off('bogus event')).should.throw()

  describe '#emit', ->
    it 'should not error on a bogus event', ->
      entity = new Fathom.Entity
      entity.emit('bogus event')
      (-> entity.emit('bogus event')).should.not.throw()

    it 'should not emit a real event', ->
      entity = new Fathom.Entity
      entity.on 'some event', ->
        @stuff_got_done = true
      entity.emit('some event')
      (entity.stuff_got_done).should.equal true
