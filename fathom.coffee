assert = (fn) ->
  if not fn()
    throw "AssertionError"

map = (array, callback) ->
  callback(item) for item in array

filter = (array, callback) ->
  [ item for item in array if callback(item) ]

reduce = (array, callback, init = null) ->
  final = init || array.shift()
  final = callback(final, item) for item in array

uniqueID = 0

getUniqueID = () ->
  uniqueID++

# Entities is a way to organize all the objects of your game.
class Entities
  constructor : ->
    @entities = []
    @entityInfo = []
  
  add : (entity, groups) ->
    if entity.__fathom?
      console.log "We found a __fathom property on the entity you passed in."
      console.log "This means that either you're using this property, or you"
      console.log "have two groups with the same object. These are both bad ideas."
      # But the 2nd one is reasonable. TODO

      throw "OhCrapException" #TODO
    
    # __fathom is a special variable on all entities that stores Fathom-related
    # information about the object
    entity.__fathom =
      "groups" : groups
      "uid" : getUniqueID()

    @entities.push entity

  get: (groups) ->
    assert -> (typeof groups == "object")
     
    results = @entities
    pass = []

    for group in groups
      for entity in results
        if group in entity.__fathom.groups
          pass.push entity
      results = pass

    results

  removeEntities : (groups) ->

  removeEntity : (entity) ->
    uid = entity.__fathom.uid
    @entities = (e for e in @entities when not e.__fathom.uid == uid)

  getEntity : (groups) ->
    result = @get groups
    assert -> result.length == 1
    
    result[0]

class Game
  @currentState = null
  @switchState = (state) ->
    @currentState = state

class Entity
  constructor : (x = 0, y = 0) ->
    @x = x
    @y = y
    @events = {}
    this

  on : (event, callback) ->
    @events[event] = @events[event] || []
    @events[event].push(callback)
    this
    
  off : (event, callback) ->
    if callback
      @events[event] = filter(@events[event], (x) -> x is callback)
    else if event
      delete @events[event]
    this

  emit : (event, args...) ->
    @events[event].apply(this, args)
    this

exports = (if typeof(module) isnt 'undefined' and module.exports then module.exports else this)
exports.Game = Game
exports.Entity
exports.Entities = Entities
