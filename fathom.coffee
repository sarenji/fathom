{$, $optional, $boolean, $optional, $number, $function, $string, $object, types} = (if typeof window == 'undefined' then (require "./types").Types else this.Types)

# TODO
# I'm not sure if I like the idea of each Entity just having a function to
# manage its groups. There are positives and negatives here.

class Util
  # Sign of a number.
  @sign: (n) ->
    if n > 0
      1
    else if n < 0
      -1
    else
      0

  @arraysEqual = (a, b) ->
    !!a && !!b && !(a<b || b<a)

  # Return a vector representing movement.
  # TODO: Support WASD also.
  @movementVector: () ->
    x = (Key.isDown(Key.Right) - Key.isDown(Key.Left))
    y = (Key.isDown(Key.Down) - Key.isDown(Key.Up))
    new Vector(x, y)

  @epsilonEq = (a, b, threshold) ->
    Math.abs(a - b) < threshold

class Point
  constructor: (@x=0, @y=0) ->
    types $optional($number), $optional($number)

  setPosition: (p) ->
    types $("Point")
    @x = p.x
    @y = p.y

  clone: () ->
    new Point @x, @y

  toRect: (size) ->
    new Rect(@x, @y, size)

  point: () ->
    new Point(@x, @y)

  eq: (p) ->
    types $("Point")
    Util.epsilonEq(@x, p.x) and Util.epsilonEq(@y, p.y)

  close: (p, threshold=1) ->
    types $("Point"), $optional($number)
    Util.epsilonEq(@x, p.x, threshold) and Util.epsilonEq(@y, p.y, threshold)

  add: (v) ->
    types $("Vector")
    @x += v.x
    @y += v.y
    this

  offscreen: (screen) ->
    types $("Rect")
    not screen.touchingPoint @

  subtract: (p) ->
    types $("Point")
    return new Vector(@x-p.x, @y-p.y)

class Vector
  constructor: (@x=0, @y=0) ->
    types $optional($number), $optional($number)

  randomize: () ->
    r = Math.floor(Math.random() * 4)
    (@x =  0; @y =  1) if r == 0
    (@x =  0; @y = -1) if r == 1
    (@x =  1; @y =  0) if r == 2
    (@x = -1; @y =  0) if r == 3
    this

  multiply: (n) ->
    types $number
    @x *= n
    @y *= n
    this

  add: (v) ->
    types $("Vector")
    @x += v.x
    @y += v.y
    this

  normalize: () ->
    mag = Math.sqrt(@x * @x + @y * @y)
    @x /= mag
    @y /= mag
    this

  nonzero: () ->
    @x != 0 or @y != 0

class Key
  @getCode: (e) ->
    #types $('KeyboardEvent')
    if not e
      e = window.event

    if e.keyCode
      code = e.keyCode
    else if e.which
      code = e.which

    code

  @addKeys: ->
    alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    @[chr] = alphabet.charCodeAt i for chr, i in alphabet

    @Left  = 37
    @Up    = 38
    @Right = 39
    @Down  = 40

  @start: (addListeners=true) ->
    types $optional($boolean)
    @addKeys()

    @keysDown = (false for x in [0..255])

    if addListeners
      document.onkeydown = (e) => @keysDown[@getCode e] = true; e.preventDefault()
      document.onkeyup = (e) => @keysDown[@getCode e] = false; e.preventDefault()

  @isDown: (key) ->
    types $number

    @keysDown[key]

  @isUp: (key) ->
    types $number
    if @keysDown[key]
      @keysDown[key] = false
      true
    else
      false

  @flush: ->
    @start(false)

# BasicHooks requires `object` to be of type StandardControllable. But that
# type doesn't exist right now TODO and it's also a horrible name so I have to
# rethink this. What it means until it does is that the controlled object must
# have a vx and a vy.
class BasicHooks
  #TODO: These function should be called with this bound to the caller.

  @stickTo: (sticker, object, dx=0, dy=0) ->
    () ->
      sticker.setPosition(object.clone().add(new Vector(dx, dy)))

  # TODO: More customization.
  # TODO: Nice accelerating controls too, perhaps.
  @rpgLike: (speed, object) =>
    types $number, $("Entity")
    () =>
      v = Util.movementVector().multiply(speed)
      object.vx += v.x
      object.vy += v.y

      object.x += object.vx
      if object.__fathom.entities.any((other) => other.collides(object))
        object.x -= object.vx
        object.vx = 0

      object.y += object.vy
      if object.__fathom.entities.any((other) => other.collides(object))
        object.y -= object.vy
        object.vy = 0


  # TODO: Pass in cutoff and decel.
  @decel: (object) =>
    types $object
    cutoff = .5
    decel = 2

    () =>
      object.vx = 0 if Math.abs(object.vx) < cutoff
      object.vy = 0 if Math.abs(object.vy) < cutoff

      object.vx /= decel
      object.vy /= decel

  @move: (object, direction) =>
    types $("Entity"), $("Vector")
    () =>
      object.add(direction)

  @onCollide: (object, type, cb) =>
    types $("Entity"), $string, $function
    () =>
      collisions = object.__fathom.entities.one(type, (other) -> other.collides(object))
      if collisions
        cb(collisions)

  @onLeaveScreen: (object, screenWidth, screenHeight, cb) =>
    () =>
      if object.x <= 0 or object.y <= 0 or object.x >= screenWidth or object.y >= screenHeight
        cb.bind(object)()

  @platformerLike: (speed, object) =>
    types $number, $("Entity"), $("Entities")
    object.vx += (Key.isDown(Key.D) - Key.isDown(Key.A)) * speed
    object.vy += 5

    # Need to check if we're on the ground before we jump
    if Key.isDown(Key.W)
      onGround = object.__fathom.entities.any (other) -> other.collides(this)
      if onGround
        object.vy -= 50


assert = (fn) ->
  if not fn()
    throw new Error("AssertionError")

uniqueID = 0

getUniqueID = () ->
  uniqueID++

# Entities is a way to organize all the objects of your game.
class Entities
  constructor: ->
    @entities = []
    @entityInfo = []

  # Adds an entity.
  add: (entity) ->
    types $("Entity")
    @entities.push entity

  # Get all Entities that match each of an array of criteria.
  #
  # * If you pass in a string, all returned objects will have that string in its
  # groups.
  # * If you pass in a function f, for all returned objects, f(any object) ==
  # true.
  # * If you pass in anything else, an error will be raised.

  get: (criteria...) ->
    #types $object #todo: not as strict as it could be
    #assert -> typeof criteria == "object"
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
            throw new Error("UnsupportedCriteriaType #{typeof item}")

      remainingEntities = pass

    remainingEntities

  one: (criteria...) ->
    results = (@get criteria...)
    if results.length
      results[0]
    else
      null

  # Returns true if there is at least 1 object that matches each criteria,
  # false otherwise.
  any: (criteria...) ->
    (@get criteria...).length > 0

  can: (decorator) ->
    decorator.call(this)

  remove: (entity) ->
    uid = entity.__fathom.uid
    @entities = (e for e in @entities when e.__fathom.uid != uid)

  getEntity: (groups) ->
    types $object
    result = @get groups
    assert -> result.length == 1

    result[0]

  # I feel like the following methods should be moved outside of Entities,
  # perhaps into a specialized base class.

  render: (context) ->
    entities = @get "renderable"
    entities.sort (a, b) -> a.depth() - b.depth()

    for entity in entities
      entity.emit "pre-render"
      entity.render context
      entity.emit "post-render"

  update: (entities) ->
    types $("Entities")
    for entity in @get "updateable"
      entity.emit "pre-update"
      entity.update entities
      entity.emit "post-update"

entities = new Entities

class Rect extends Point
  constructor: (@x, @y, @size) ->
    #types $number, $number, $number TYPE TODO
    super @x, @y
    @right = @x + @size
    @bottom = @y + @size

  # Returns true if the current rect touches rect `rect`.
  touchingRect: (rect) ->
    types $("Rect")
    not (other.x              > @x + @size or
         other.x + other.size < @x         or
         other.y              > @y + @size or
         other.y + other.size < @y       )

  # Returns true if this rect contains point `point`.
  touchingPoint: (point) ->
    types $("Point")
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
  constructor: (x = 0, y = 0, size = 20) ->
    #types $number, $number, $number
    super

    @__fathom =
      uid      : getUniqueID()
      events   : {}
      entities : entities
    entities.add @

  # This will eventually be removed.
  entities: ->
    @__fathom.entities

  # Adds a `callback` function to a string `event`.
  # Callbacks are stackable, and are called in order of addition.
  on: (event, callback) ->
    types $string, $function
    @__fathom.events[event] = chain = @__fathom.events[event] or []
    chain.push(callback) unless callback in chain

    # Return the Entity object for easy chainability.
    this

  # If a `callback` is provided, removes the callback from an event.
  # Fails silently if no callback was found. If no `callback` is
  # provided, all callbacks attached to an event are removed.
  off: (event, callback = null) ->
    types $string, $optional($function)
    #TODO: I don't like how this is a non-noisy failure.
    if callback
      if @__fathom.events[event]
        @__fathom.events[event] = (hook for hook in @__fathom.events[event] when hook isnt callback)
        delete @__fathom.events[event] if @__fathom.events[event].length == 0
      else
       throw new Error("Entity#off called on an event that the entity did not have.")
    else if event
      if @__fathom.events[event]
        delete @__fathom.events[event]
      else
        throw new Error("Entity#off called on an event that the entity did not have.")

    # Return the Entity object for easy chainability.
    this

  # Triggers an `event` attached to this Entity. If the Entity does
  # not have the event, the function fails silently.
  emit: (event, args...) ->
    if event of @__fathom.events
      hook.call(this) for hook in @__fathom.events[event]

    # Return the Entity object for easy chainability.
    this

  die: () ->
    @.__fathom.entities.remove @

  # Returns an array of the groups this Entity is a member of. Must be
  # implemented in a subclass.
  groups: () ->
    throw new Error("NotImplementedException")

  # Renders the Entity. Must be implemented in a subclass if it has group
  # "renderable".
  render: (context) ->
    throw new Error("NotImplementedException")

  # Returns true if this collides with other, else false.
  collides: (other) ->
    $("Entity")
    @.__fathom.uid != other.__fathom.uid and @touchingRect other

  # Updates the Entity. Must be implemented in a subclass if it has group
  # "updateable".
  update: () ->
    throw new Error("NotImplementedException")

  # Returns the depth at which the Entity will be rendered (like Z-Ordering).
  # Can be reimplemented in a subclass.
  depth: () ->
    0

class Tile extends Rect
  constructor: (@x, @y, @size, @type) ->
    types $number, $number, $number, $number
    super(@x, @y, @size)

  render: (context) ->
    if @type == 0
      context.fillStyle = "#f00"
    else if @type == 1
      context.fillStyle = "#ff0"

    context.fillRect @x, @y, @width, @height


# Generic health bar

class Bar extends Entity
  constructor: (@x, @y, @width=50, @fillColor="#0f0", @emptyColor="#f00") ->
    types $number, $number, $optional($number), $optional($string), $optional($string)

    @borderColor = "#000"
    @borderWidth = 1
    @height = 10

    @amt = 50
    @total = 100

    super @x, @y, @height # TODO: passing in the size really has no meaning here.
                          # i guess that we want @width=@height=@size as a default but not
                          # as a requirement.
  groups: -> ["renderable", "updateable", "bar"]
  collides: -> false
  update: ->

  render: (context) ->
    # fill border
    context.fillStyle = @borderColor
    context.fillRect @x, @y, @width, @height

    # fill empty color
    context.fillStyle = @emptyColor
    context.fillRect @x + @borderWidth, @y + @borderWidth, @width - @borderWidth * 2, @height - @borderWidth * 2

    coloredWidth = (@amt / @total) * (@width - 2)
    # fill full color
    context.fillStyle = @fillColor
    context.fillRect @x + @borderWidth, @y + @borderWidth, coloredWidth, @height - @borderWidth * 2

class FollowBar extends Bar
  constructor: (@follow, rest...) ->
    super(rest...)
    @on "pre-update", Fathom.BasicHooks.stickTo(@, @follow, 0, -10)

class Pixel
  constructor: (@r, @g, @b, @a) -> types $number, $number, $number, $number
  eq: (p) ->
    types $("Pixel")
    @r == p.r and @g == p.g and @b == p.b and @a = p.a

loadImage = (loc, callback) ->
  img = document.createElement('img')
  img.onload = () ->
    temp_context.drawImage(img, 0, 0)
    data = temp_context.getImageData(0, 0, img.width, img.height).data
    pixels = ([] for x in [0...img.width])

    for x in [0...img.width]
      for y in [0...img.height]
        z = (x * img.width + y) * 4
        pixels[y][x] = new Pixel(data[z], data[z+1], data[z+2], data[z+3])

    callback(pixels)

  img.src = loc

class Map extends Entity
  constructor: (@width, @height, @size) ->
    types $number, $number, $number
    super 0, 0, @size

    @tiles = ((null for b in [0...height]) for a in [0...width])
    @data = undefined
    @corner = new Point(0, 0)

  setTile: (x, y, type) =>
    types $number, $number, $number
    @tiles[x][y] = new Tile(x * @size, y * @size, @size, type)

  # Set the top right corner of the visible map.
  # TODO: This has a bad name. TODO and now it's even worse because it's a delta.
  setCorner: (diff) ->
    types $("Vector")
    @corner.add(diff.multiply(@width))

    for x in [0... + @width]
      for y in [0... + @height]
        if @data[@corner.x + x][@corner.y + y].eq(new Pixel(0, 0, 0, 255)) #TODO. Too specific.
          val = 1
        else
          val = 0

        @setTile(x, y, val)

  fromImage: (loc, corner, callback) ->
    types $string, $("Vector"), $function
    if @data
      @setCorner(corner)
      return

    loadImage loc, (data) =>
      @data = data
      @setCorner(corner)
      callback()

  groups: ->
    ["renderable", "wall", "map"]

  collides: (other) ->
    types $('Rect')
    #TODO insanely inefficient.
    for x in [0...@width]
      for y in [0...@height]
        if @tiles[x][y].type == 1 and @tiles[x][y].touchingRect other
          return true

    return false

  render: (context) ->
    for x in [0...@width]
      for y in [0...@height]
        @tiles[x][y].render context

class StaticImage extends Entity
  constructor: (source, destination) ->
    super destination.x, destination.y, destination.size
    #TODO: Grab from file, use source etc

class Text extends Entity
  constructor: (@text, x=0, y=0, opts={}) ->
    types $string, $optional($number), $optional($number), $optional($object)
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
  groups: -> ["renderable"]
  render: (context) ->
    context.fillText @text, @x, @y
  depth: -> 2
  collides: -> false

class TextBox extends Text
  constructor: (text, x=0, y=0, @width=100, @height=-1, opts={}) ->
    types $string, $number, $number, $optional($number), $optional($number), $optional($object)
    super text, x, y, opts

  groups: -> ["renderable", "updateable"]

  update: () ->
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

  render: (context) ->
    for phrase, i in @phrases
      context.fillText phrase, @x, @y + @size * i

# To start Fathom, document.body must exist.
ready = (callback) ->
  types $function
  if document.body then callback() else setTimeout (-> ready callback), 250

# TODO: This implementation is not complete.
fixedInterval = (fn, fps=24) ->
  types $function, $optional($number)
  setInterval fn, 1000/fps

context = null # Graphics context for the game.
temp_context = null # Context for temporary stuff i.e. reading pixel data (invisible).

# Returns an estimate of the FPS (strictly: the number of times this function
# has been called per second). Will return null the first time.
getFPS = () ->
  now = +new Date()
  thisFrameFPS = 1000 / (now - getFPS.lastUpdate)

  getFPS.fps += (thisFrameFPS - getFPS.fps) / getFPS.fpsFilter
  getFPS.lastUpdate = now
  getFPS.fps

getFPS.fpsFilter = 20
getFPS.lastUpdate = +new Date()
getFPS.fps = 0

initialize = (gameLoop, canvasID) ->
  types $function, $string
  ready () ->
    canv = document.createElement "canvas"
    canv.width = canv.height = 500
    temp_context = canv.getContext('2d')

    Key.start()

    canv = document.getElementById canvasID
    context = canv.getContext('2d')

    wrappedLoop = () ->
      gameLoop context
      entities.update entities
      entities.render context

    fixedInterval wrappedLoop

# Export necessary things outside of closure.
exports = (module?.exports or this)
exports.Fathom =
  Util       : Util
  Key        : Key
  Entity     : Entity
  Entities   : Entities
  BasicHooks : BasicHooks
  Text       : Text
  Rect       : Rect
  Bar        : Bar
  FollowBar  : FollowBar
  TextBox    : TextBox
  Map        : Map
  Point      : Point
  Vector     : Vector
  initialize : initialize
  getFPS     : getFPS
