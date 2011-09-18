class Keys
  getCode : (e) ->
    if not e
      e = window.event

    if e.keyCode
      code = e.keyCode
    else if e.which
      code = e.which

    code

  constructor : ->
    @keysDown = {}

    document.onkeyup = (e) ->
      keysDown[getCode e] = true

  isDown : (key) ->
    keysDown[key]

  isUp : (key) ->
    if keysDown[key]
      keysDown[key] = false
      true
    else
      false

  flush : ->
    @keysDown = {}

assert = (fn) ->
  if not fn()
    throw "AssertionError"

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
    @entities.push entity

  # Get all Entities that match each of an array of criteria.
  #
  # * If you pass in a string, all returned objects will have that string in its
  # groups.
  # * If you pass in a function f, for all returned objects, f(any object) ==
  # true.
  # * If you pass in anything else, an error will be raised.
  
  get : (criteria) ->
    assert -> typeof criteria == "object"
     
    remainingEntities = @entities

    for item in criteria
      pass = []

      for entity in remainingEntities
        switch typeof item
          when "string"
            if item in entity.__fathom.groups
              pass.push entity
          when "function"
            if item entity
              pass.push entity
          else
            throw "UnsupportedCriteriaType #{typeof item}"

      remainingEntities = pass

    remainingEntities

  # Returns true if there is at least 1 object that matches each criteria,
  # false otherwise.
  any : (criteria) ->
    assert -> typeof criteria == "object"

    return (@get criteria).length > 0

  removeEntities : (groups) ->

  removeEntity : (entity) ->
    uid = entity.__fathom.uid
    @entities = (e for e in @entities when not e.__fathom.uid == uid)

  getEntity : (groups) ->
    result = @get groups
    assert -> result.length == 1
    
    result[0]

  # I feel like the following methods should be moved outside of Entities,
  # perhaps into a specialized base class.

  render : (context) ->
    entities = @get ["renderable"]
    entities.sort (a, b) -> a.depth() - b.depth()

    for entity in entities
      entity.emit "pre-render"
      entity.render context
      entity.emit "post-render"

  update : (entities) ->
    for entity in @get ["updateable"]
      entity.emit "pre-update"
      entity.update entities
      entity.emit "post-update"

class Game
  @currentState = null
  @switchState = (state) ->
    @currentState = state

# Entity
# ------
#
# Encapsulates all the render and update logic independent
# to one Entity.
#
# All entities have an `.on` method, which takes an event name
# and a callback. These callbacks are called by the `.emit` method,
# which takes an event name.
class Entity
  constructor : (x = 0, y = 0, size = 20) ->
    @x = x
    @y = y
    @size = size
    @__fathom =
      groups : @groups()
      uid    : getUniqueID()
      events : {}

  # Returns true if the current entity touches entity `other`.
  touchingEntity : (other) ->
    not ((other.x          ) > (@x + @size) or
         (other.x + other.size) < (@x        ) or
         (other.y             ) > (@y + @size) or
         (other.y + other.size) < (@y       ))

  # Adds a `callback` function to a string `event`.
  # Callbacks are stackable, and are called in order of addition.
  on : (event, callback) ->
    @__fathom.events[event] = chain = @__fathom.events[event] or []
    chain.push(callback) unless callback in chain

    # Return the Entity object for easy chainability.
    this
  
  # If a `callback` is provided, removes the callback from an event.
  # Fails silently if no callback was found. If no `callback` is
  # provided, all callbacks attached to an event are removed.
  off : (event, callback = null) ->
    if callback
      @__fathom.events[event] = (hook for hook in @__fathom.events[event] when hook isnt callback)
      delete @__fathom.events[event] if @__fathom.events[event].length == 0
    else if event
      delete @__fathom.events[event]

    # Return the Entity object for easy chainability.
    this

  # Triggers an `event` attached to this Entity. If the Entity does
  # not have the event, the function fails silently.
  emit : (event, args...) ->
    if event of @__fathom.events
      hook.call(this) for hook in @__fathom.events[event]

    # Return the Entity object for easy chainability.
    this

  # Returns an array of the groups this Entity is a member of. Must be
  # implemented in a subclass.
  groups : () ->
    []

  # Renders the Entity. Must be implemented in a subclass if it has group
  # "renderable".
  render : (context) ->
    throw "NotImplementedException"

  # Updates the Entity. Must be implemented in a subclass if it has group
  # "updateable".
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

# A weak approximation of onReady from jQuery. All we care about to start up
# Fathom is that document.body exists, which may not immediately be true.
ready = (callback) ->
  if document.body then callback() else setTimeout (-> ready callback), 250

# Export necessary things outside of closure.
exports = (module?.exports or this)
exports.Fathom =
  Game     : Game
  Keys     : Keys
  Entity   : Entity
  Entities : Entities
  ready    : ready
