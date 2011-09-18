fathom = require "../fathom.js"
Fathom = fathom.Fathom

describe 'Entity', ->
  describe '#on', ->
    it 'should add a callback for new events', ->
      entity = new Fathom.Entity
      event  = 'some event'

      expect(entity.__events[event]).toBeUndefined()
      entity.on event, -> @david_rules = true
      expect(entity.__events[event].length).toEqual 1

    it 'should add callbacks to existing events', ->
      entity = new Fathom.Entity
      event  = 'some event'
      entity.on event, -> @david_rules = true
      entity.on event, -> @grant_too = true

      expect(entity.__events[event].length).toEqual 2

    it 'should not add the same callback to the same event', ->
      entity = new Fathom.Entity
      event  = 'some event'
      david  = -> @david_rules = true
      entity.on event, david
      entity.on event, david

      expect(entity.__events[event].length).toEqual 1

    it 'can add the same callback to two different events', ->
      entity = new Fathom.Entity
      david  = -> @david_rules = true
      entity.on 'some event',    -> david
      entity.on 'another event', -> david

      expect(entity.__events['some event'].length).toEqual 1
      expect(entity.__events['another event'].length).toEqual 1

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
        expect(entity.__events[event].length).toEqual 1
        expect(entity.__events[event][0]).toBe grant

      it 'should remove empty arrays to save memory', ->
        entity.off event, grant
        expect(entity.__events[event]).toBeUndefined()

    describe 'when only providing the event name', ->
      entity = new Fathom.Entity
      david  = -> @david_rules = true
      grant  = -> @grant_too = true
      event  = 'some event'
      entity.on event, david
      entity.on event, grant

      it 'should remove all attached callbacks', ->
        entity.off event
        expect(entity.__events[event]).toBeUndefined()

    describe 'on a bogus event', ->
      describe 'when providing a specific callback', ->
        entity = new Fathom.Entity
        it 'should fail silently', ->
          expect(-> entity.off('bogus event', ->)).not.toThrow(new Error)

      describe 'when only providing the event name', ->
        entity = new Fathom.Entity
        it 'should fail silently', ->
          expect(-> entity.off('bogus event')).not.toThrow(new Error)

  describe '#emit', ->
    it 'should not error on a bogus event', ->
      entity = new Fathom.Entity
      entity.emit('bogus event')
      expect(-> entity.emit('bogus event')).not.toThrow(new Error)

    it 'should not error on real event', ->
      entity = new Fathom.Entity
      entity.on 'some event', ->
        @stuff_got_done = true
      entity.emit('some event')
      expect(entity.stuff_got_done).toEqual true