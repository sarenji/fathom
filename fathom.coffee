assert = (fn) ->
  if not fn()
    throw "AssertionError"

map = (array, callback) ->
  callback(item) for item in array

filter = (array, callback) ->
  item for item in array if callback(item)

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
  
  # Adds an entity based on its groups. TODO: Will not update where an entity
  # can be found if its groups change. I'm not sure if it should or not.
  add : (entity) ->
    if entity.__fathom?
      console.log "We found a __fathom property on the entity you passed in."
      console.log "This means that either you're using this property, or you"
      console.log "have two groups with the same object. These are both bad ideas."
      # But the 2nd one is reasonable. TODO

      throw "OhCrapException" #TODO
    
    # __fathom is a special variable on all entities that stores Fathom-related
    # information about the object
    entity.__fathom =
      "groups" : entity.groups()
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

'''
Entity
------

Encapsulates all the render and update logic independent
to one Entity.

All entities have an `.on` method, which takes an event name
and a callback. These events are callable by the `.emit` method,
which takes an event name.
'''
class Entity
  constructor : (x = 0, y = 0, size = 20) ->
    @x = x
    @y = y
    @size = size
    @events = {}
    this

  # Adds a `callback` function to a string `event`.
  # Callbacks are stackable, and are called in order of addition.
  # Returns the Entity object for easy chainability.
  on : (event, callback) ->
    @events[event] = @events[event] || []
    @events[event].push(callback)
    this
  
  # If a `callback` is provided, removes the callback from an event.
  # Fails silently if no callback was found. If no `callback` is
  # provided, all callbacks attached to an event are removed.
  # Returns the Entity object for easy chainability.
  off : (event, callback = null) ->
    if callback
      @events[event] = filter(@events[event], (x) -> x is callback)
    else if event
      delete @events[event]
    this

  # Triggers an `event` attached to this Entity and passes the remaining
  # arguments to the callbacks. If the Entity does not have the event, the
  # function fails silently.
  # Returns the Entity object for easy chainability.
  emit : (event, args...) ->
    if event of @events
      hook.apply(this, args) for hook in @events[event]
    this

  # Returns an array of the groups this Entity is a member of. Must be
  # implemented in a subclass.
  groups : () ->
    throw "NotImplementedException"

  # Renders the Entity. Must be implemented in a subclass.
  render : (context) ->
    throw "NotImplementedException"

  # Updates the Entity. Must be implemented in a subclass.
  update : (entities) ->
    throw "NotImplementedException"

  # Returns the depth at which the Entity will be rendered (like Z-Ordering).
  # Can be reimplemented in a subclass.
  depth : () ->
    0


class StaticImage extends Entity
  constructor : (source, destination) ->
    super destination.x, destination.y, destination.size
    #TODO: Grab from file, use source etc

exports = (if typeof(module) isnt 'undefined' and module.exports then module.exports else this)
exports.Fathom =
  Game     : Game
  Entity   : Entity
  Entities : Entities
