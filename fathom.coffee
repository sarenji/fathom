class Key
  @A = 65
  @D = 68
  @W = 87
  @S = 83

  @getCode : (e) ->
    if not e
      e = window.event

    if e.keyCode
      code = e.keyCode
    else if e.which
      code = e.which

    code

  @start : ->
    @keysDown = {}
    @flush()

    document.onkeydown = (e) =>
      console.log @getCode e
      @keysDown[@getCode e] = true

    document.onkeyup = (e) =>
      @keysDown[@getCode e] = false

  @isDown : (key) ->
    @keysDown[key]

  @isUp : (key) ->
    if @keysDown[key]
      @keysDown[key] = false
      true
    else
      false

  @flush : ->
    @keysDown = {}
    @keysDown[x] = false for x in [0..255]


# BasicControls provides callbacks for simple arrow-based movement. We choose
# to return callbacks because we get some nice convience with callback-related
# hooks, especially `pre-update`. See Depths TODO for a good example of this.
# 
# BasicControls requires `object` to be of type StandardControllable. But that
# type doesn't exist right now TODO and it's also a horrible name so I have to
# rethink this. What it means until it does is that the controlled object must
# have a vx and a vy.
class BasicControls
  #TODO: When/if I understand coffeescript better: I should be able to not have
  #the user pass in object; it'll always be this, so I should just be able to
  #bind with the fat arrow. But that doesn't seem to work here. Can't figure
  #out why.
  @RPGLike : (speed, object) =>
    () =>
      object.vx += (Key.isDown(Key.D) - Key.isDown(Key.A)) * speed
      object.vy += (Key.isDown(Key.S) - Key.isDown(Key.W)) * speed

  @PlatformerLike : (speed, object) =>
    () =>
      object.vx += (Key.isDown(Key.D) - Key.isDown(Key.A)) * 2
      object.vy += 2

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
  
  # Adds an entity.
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
            if item in entity.groups()
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
    @currentState.emit "switch off" if @currentState?
    @currentState = state
    @currentState.emit "switch on"

# State is just a convenience class that Game uses. It subclasses from
# Entities and may have extra methods or instance variables added to it in
# the future. It's advised to use this for managing game state over a regular
# Entities object, as things may change in the future.
class State extends Entities

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
  constructor : (@x = 0, @y = 0, @size = 20) ->
    @__fathom =
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
    throw "NotImplementedException"

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

#This implementation is not complete.
fixedInterval = (fn, fps) ->
  setInterval fn, 1000/fps

initialize = (gameLoop) ->
  ready () ->
    Key.start()

    canv = document.createElement "canvas"
    canv.width = canv.height = 500 #TODO: 500
    document.body.appendChild(canv)

    context = canv.getContext('2d')

    fixedInterval (() -> (gameLoop context)), 20

# Export necessary things outside of closure.
exports = (module?.exports or this)
exports.Fathom =
  Game          : Game
  Key           : Key
  Entity        : Entity
  Entities      : Entities
  BasicControls : BasicControls
  initialize    : initialize
