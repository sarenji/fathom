# Type annotation for CoffeeScript/JavaScript.
# TODO: Can probably be moved into some sort of metautil...

getType = (someObj) ->
  funcNameRegex = /function (.+)\(/
  results = (funcNameRegex).exec((someObj).constructor.toString())
  results[1]

# slightly-better-than-js-typing

Types = {}

OUTER_ONLY = 0
EVERYTHING = 1
NEXT_FUNCTION = 2

Types.$string = (type = EVERYTHING) -> "string"
Types.$number = (type = EVERYTHING) -> "number"
Types.$object = (type = EVERYTHING) -> "object"
Types.$ = (type) ->
  (how_deep) ->
    if how_deep == OUTER_ONLY
      "user type"
    else
      type

Types.$array = (type) ->
  (how_deep) ->
    if how_deep == OUTER_ONLY
      "array"
    else if how_deep == NEXT_FUNCTION
      type
    else
      "array(#{type(EVERYTHING)})"


# TODO: correct number of arguments

# You are not expected to understand this.
Types.types = (typeList...) ->
  # Ascend the stack trace to get args of calling function.
  args = Array.prototype.slice.call Types.types.caller.arguments

  throwError = (expected, received) ->
    err = "TypeError: got #{received}, expected #{expected} in #{Types.types.caller}"

    console.log err
    throw "TypeError"

  for arg, i in args
    if typeof typeList[i] == "string"
      good = getType(arg) == typeList[i]
      if not good
        throwError typeList[i], getType(arg)
      continue

    switch typeList[i](OUTER_ONLY)
      when "string"
        if typeof arg != "string"
          throwError typeList[i](true), typeof arg
      when "number"
        if typeof arg != "number"
          throwError typeList[i](true), typeof arg
      when "object"
        if typeof arg != "object"
          throwError typeList[i](true), typeof arg
      when "array"
        good = (arg.length == 0 or (typeof arg[0]) == typeList[i](NEXT_FUNCTION)())

        if not good
          throwError typeList[i](EVERYTHING), typeof arg
      when "user type"
        good = typeList[i](EVERYTHING) == getType(arg)
        if not good
          throwError "user type: #{typeList[i](EVERYTHING)}", getType(arg)
      else
        throw "unknown type #{typeList[i](OUTER_ONLY)}"

# TODO
# I'm not sure if I like the idea of each Entity just having a function to
# manage its groups. There are positives and negatives here.

class Point
  constructor : (x, y) ->
    @x = x
    @y = y

class Key
  @getCode : (e) ->
    if not e
      e = window.event

    if e.keyCode
      code = e.keyCode
    else if e.which
      code = e.which

    code

  @addKeys : ->
    alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    @[chr] = alphabet.charCodeAt i for chr, i in alphabet

  @start : ->
    @addKeys()

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


# BasicHooks provides callbacks for simple arrow-based movement. We choose
# to return callbacks because we get some nice convience with callback-related
# hooks, especially `pre-update`. See Depths TODO for a good example of this.
# 
# BasicHooks requires `object` to be of type StandardControllable. But that
# type doesn't exist right now TODO and it's also a horrible name so I have to
# rethink this. What it means until it does is that the controlled object must
# have a vx and a vy.
class BasicHooks
  #TODO: When/if I understand coffeescript better: I should be able to not have
  #the user pass in object; it'll always be this, so I should just be able to
  #bind with the fat arrow. But that doesn't seem to work here. Can't figure
  #out why.

  # TODO: More customization.
  # TODO: Nice accelerating controls too, perhaps.
  @rpgLike : (speed, object) =>
    () =>
      object.vx += (Key.isDown(Key.D) - Key.isDown(Key.A)) * speed
      object.vy += (Key.isDown(Key.S) - Key.isDown(Key.W)) * speed

  # TODO: Pass in cutoff and decel.
  @decel : (object) =>
    cutoff = .5
    decel = 2

    () =>
      object.vx = 0 if Math.abs(object.vx) < cutoff
      object.vy = 0 if Math.abs(object.vy) < cutoff

      object.vx /= decel
      object.vy /= decel

  @moveForward: (object, direction) =>
    () =>
      object.x += direction.x
      object.y += direction.y

  @dieAtWall: (object, entities) =>
    () =>

  @dieOffScreen: (object, screen_width, screen_height) =>
    () =>
      if object.x <= 0 or object.y <= 0 or object.x >= screen_width or object.y >= screen_height
        object.die()

  # TODO: No idea how we're going to get entities here.
  @platformerLike : (speed, object, entities) =>
    object.vx += (Key.isDown(Key.D) - Key.isDown(Key.A)) * speed
    object.vy += 5

    # Need to check if we're on the ground before we jump
    if Key.isDown(Key.W)
      onGround = entities.any ["wall", (other) -> other.touchingPoint(x : object.x, y : object.y + object.size + 5)]
      console.log onGround
      if onGround
        object.vy -= 50


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

  #TODO: "criteria...". No reason to require it to be an array.
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

  can : (decorator) ->
    decorator.call(this)

  removeEntities : (groups) ->

  removeEntity : (entity) ->
    uid = entity.__fathom.uid
    @entities = (e for e in @entities when e.__fathom.uid != uid)

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

class Rect
  constructor: (@x, @y, @size) ->
    @right = @x + @size
    @bottom = @y + @size

  # Returns true if the current rect touches rect `other`.
  touchingRect : (other) ->
    not (other.x              > @x + @size or
         other.x + other.size < @x         or
         other.y              > @y + @size or
         other.y + other.size < @y       )

  # Returns true if this rect contains point `point`.
  touchingPoint : (point) ->
    @x <= point.x <= @x + @size and @y <= point.y <= @y + @size

# Entity
# ------
#
# Encapsulates all the render and update logic independent
# to one Entity.
#
# All entities have an `.on` method, which takes an event name
# and a callback. These callbacks are called by the `.emit` method,
# which takes an event name.
class Entity extends Rect
  constructor : (x = 0, y = 0, size = 20) ->
    super

    @__fathom =
      uid    : getUniqueID()
      events : {}

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

  die: (entities) ->
    entities.removeEntity this

  # Returns an array of the groups this Entity is a member of. Must be
  # implemented in a subclass.
  groups : () ->
    throw "NotImplementedException"

  # Renders the Entity. Must be implemented in a subclass if it has group
  # "renderable".
  render : (context) ->
    throw "NotImplementedException"

  # Returns true if this collides with other, else false.
  collides : (other) ->
    false

  # Updates the Entity. Must be implemented in a subclass if it has group
  # "updateable".
  update : (entities) ->
    throw "NotImplementedException"

  # Returns the depth at which the Entity will be rendered (like Z-Ordering).
  # Can be reimplemented in a subclass.
  depth : () ->
    0

class Tile extends Rect
  constructor : (@x, @y, @size, @type) ->
    super(@x, @y, @size)

  render: (context) ->
    if @type == 0
      context.fillStyle = "#f00"
    else if @type == 1
      context.fillStyle = "#ff0"

    context.fillRect @x, @y, @size, @size

class Map extends Entity
  constructor : (@width, @height, @size) ->
    super 0, 0, @size

    @tiles = ((null for b in [0...height]) for a in [0...width])

  setTile : (x, y, type) =>
    @tiles[x][y] = new Tile(x * @size, y * @size, @size, type)
    @tiles[x][y]

  groups : ->
    ["renderable", "wall"]

  collides : (other) ->
    #TODO insanely inefficient.
    for x in [0...@width]
      for y in [0...@height]
        if @tiles[x][y].type == 1 and @tiles[x][y].touchingRect other
          return true

    return false

  render : (context) ->
    for x in [0...@width]
      for y in [0...@height]
        @tiles[x][y].render context

class StaticImage extends Entity
  constructor : (source, destination) ->
    super destination.x, destination.y, destination.size
    #TODO: Grab from file, use source etc

class Text extends Entity
  constructor : (@text, x=0, y=0, opts={}) ->
    super x, y
    @color    = opts.color    || "#000000"
    @baseline = opts.baseline || "top"
    @size     = opts.size     || 16
    @font     = opts.font     || "#{@size}px Courier New"
    setup     = =>
      context.fillStyle    = @color
      context.font         = @font
      context.textBaseline = @baseline
    @on 'pre-update', setup
    @on 'pre-render', setup
  groups : -> ["renderable"]
  render : (context) ->
    context.fillText @text, @x, @y
  depth : -> 2

class TextBox extends Text
  constructor : (text, x=0, y=0, @width=100, @height=-1, opts={}) ->
    super text, x, y, opts

  groups : -> ["renderable", "updateable"]

  update : (entities) ->
    # split text into chunks
    words         = @text.split(' ')
    phrases       = []
    currentPhrase = words.shift()
    oldPhrase     = ""

    # find wrappings
    for word in words
      oldPhrase      = currentPhrase
      currentPhrase += " #{word}"
      if context.measureText(currentPhrase).width > @width
        currentPhrase = word
        phrases.push(oldPhrase)
        oldPhrase = ""
    phrases.push(currentPhrase)

    # store wrapped phrases
    @phrases = phrases

  render : (context) ->
    for phrase, i in @phrases
      context.fillText phrase, @x, @y + @size * i

# To start Fathom, document.body must exist.
ready = (callback) ->
  if document.body then callback() else setTimeout (-> ready callback), 250

# TODO: This implementation is not complete.
fixedInterval = (fn, fps=24) ->
  setInterval fn, 1000/fps

context = null
initialize = (gameLoop, canvasID) ->
  ready () ->
    Key.start()

    canv = document.getElementById canvasID
    context = canv.getContext('2d')

    fixedInterval (() -> (gameLoop context))

# Export necessary things outside of closure.
exports = (module?.exports or this)
exports.Types = Types
exports.Fathom =
  Game       : Game
  Key        : Key
  Entity     : Entity
  Entities   : Entities
  BasicHooks : BasicHooks
  Text       : Text
  TextBox    : TextBox
  Map        : Map
  initialize : initialize
  context    : context
