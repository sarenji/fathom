fathom = require "../fathom.js"
Fathom = fathom.Fathom

describe 'Entity', ->
  describe '#emit', ->
    it 'should not error on a bogus event', ->
      entity = new Fathom.Entity
      entity.emit('bogus event')
      expect(-> entity.emit('bogus event')).not.toThrow(new Error)

    it 'should not error on real event without args', ->
      entity = new Fathom.Entity
      entity.on 'some event', ->
        @stuff_got_done = true
      entity.emit('some event')
      expect(entity.stuff_got_done).toEqual true

    it 'should not error on real event with args', ->
      entity = new Fathom.Entity
      entity.on 'some event', (number) ->
        @number = number
      entity.emit('some event', 42)
      expect(entity.number).toEqual(42)