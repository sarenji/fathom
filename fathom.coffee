{Optional, types} = (if typeof window == 'undefined' then (require "./types").Types else this.Types)

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

  @randRange = (low, high) -> low + Math.floor(Math.random() * (high - low))
  @randElem = (arr) -> arr[Util.randRange(0, arr.length)]

class Color
  constructor: (@r=0, @g=0, @b=0) ->

  toString: () -> "##{@r.toString(16)[0]}#{@g.toString(16)[0]}#{@b.toString(16)[0]}"

  randomizeRed  : (low=0, high=255) -> @r = Util.randRange(low, high); @
  randomizeGreen: (low=0, high=255) -> @g = Util.randRange(low, high); @
  randomizeBlue : (low=0, high=255) -> @b = Util.randRange(low, high); @

class Tick
  @ticks = 0

class Point
  constructor: (@x=0, @y=0) ->
    types(Optional(Number), Optional(Number))

  setPosition: (p) ->
    types(Point)
    @x = p.x
    @y = p.y

  clone: () ->
    new Point @x, @y

  toRect: (width, height=width) ->
    types(Number, Optional(Number))
    new Rect(@x, @y, width, height)

  point: () ->
    new Point(@x, @y)

  eq: (p) ->
    types(Point)
    Util.epsilonEq(@x, p.x) and Util.epsilonEq(@y, p.y)

  close: (p, threshold=1) ->
    types(Point, Optional(Number))
    Util.epsilonEq(@x, p.x, threshold) and Util.epsilonEq(@y, p.y, threshold)

  add: (v) ->
    types(Vector)
    @x += v.x
    @y += v.y
    this

  offscreen: (screen) ->
    types(Rect)
    not screen.touchingPoint @

  subtract: (p) ->
    types(Point)
    return new Vector(@x-p.x, @y-p.y)

class Vector
  constructor: (@x=0, @y=0) ->
    types(Optional(Number), Optional(Number))

  eq: (v) ->
    types(Vector)
    @x == v.x and @y == v.y

  randomize: () ->
    r = Math.floor(Math.random() * 4)
    (@x =  0; @y =  1) if r == 0
    (@x =  0; @y = -1) if r == 1
    (@x =  1; @y =  0) if r == 2
    (@x = -1; @y =  0) if r == 3
    this

  multiply: (n) ->
    types(Number)
    @x *= n
    @y *= n
    this

  divide: (n) ->
    types Number
    @x /= n
    @y /= n
    this

  add: (v) ->
    types(Vector)
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
    types(Optional(Boolean))
    @addKeys()

    @keysDown = (false for x in [0..255])

    if addListeners
      document.onkeydown = (e) => @keysDown[@getCode e] = true; if (@getCode e) in [@Left, @Up, @Right, @Down] then e.preventDefault()
      document.onkeyup = (e) => @keysDown[@getCode e] = false; if (@getCode e) in [@Left, @Up, @Right, @Down] then e.preventDefault()

  @isDown: (key) ->
    types(Number)

    @keysDown[key]

  @isUp: (key) ->
    types(Number)
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
  @stickTo: (stuckTo, dx=0, dy=0) ->
    () -> @setPosition(stuckTo.clone().add(new Vector(dx, dy)))

  @slideTo: (slideTo, speed=20) ->
    () -> @add(slideTo.subtract(@).divide(speed))

  # TODO: More customization.
  # TODO: Nice accelerating controls too, perhaps.
  @rpgLike: (speed) ->
    types(Number)
    () ->
      v = Util.movementVector().multiply(speed)
      @vx += v.x
      @vy += v.y

      @x += @vx
      @y += @vy

  @resolveCollisions: () ->
    () ->
      if @__fathom.entities.any((other) => other.collides @)
        @x -= @vx
        @vx = 0

      if @__fathom.entities.any((other) => other.collides @)
        @y -= @vy
        @vy = 0


  # TODO: Pass in cutoff and decel.
  @decel: () ->
    cutoff = .5
    decel = 2

    () ->
      @vx = 0 if Math.abs(@vx) < cutoff
      @vy = 0 if Math.abs(@vy) < cutoff

      @vx /= decel
      @vy /= decel

  @move: (direction) ->
    types(Vector)
    () -> @add direction

  @onCollide: (type, cb) ->
    types(String, Function)
    () ->
      collision = @__fathom.entities.one(type, (other) => other.collides(@))
      if collision
        cb.bind(@)(collision)

  @onLeaveMap: (object, map, cb) =>
    () =>
      if object.x <= 0 or object.y <= 0 or object.x >= map.width or object.y >= map.height
        cb.bind(object)()

  @platformerLike: (speed, object) =>
    types(Number, Entity, Entities)
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
    types(Entity)
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
            if item[0] == "!"
              if item[1..] not in entity.groups()
                pass.push entity
            else
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
    types(Object)
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
    types(Entities)
    for entity in @get "updateable"
      entity.emit "pre-update"
      entity.update entities
      entity.emit "post-update"

entities = new Entities

class Rect extends Point
  constructor: (@x, @y, @width, @height=@width) ->
    types(Number, Number, Number, Optional(Number))
    super @x, @y
    @right = @x + @width
    @bottom = @y + @height

  # Returns true if the current rect touches rect `rect`.
  touchingRect: (rect) ->
    types(Rect)
    not (rect.x                > @x + @width  or
         rect.x + rect.width  < @x           or
         rect.y                > @y + @height or
         rect.y + rect.height < @y           )

  # Returns true if this rect contains point `point`.
  touchingPoint: (point) ->
    types(Point)
    @x <= point.x <= @x + @width and @y <= point.y <= @y + @height

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
  constructor: (@x = 0, @y = 0, @width = 20, @height = @width, @color="#000") ->
    types(Optional(Number), Optional(Number), Optional(Number), Optional(Number), Optional(String))

    super(@x, @y, @width, @height)

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
    types(String, Function)
    @__fathom.events[event] = chain = @__fathom.events[event] or []
    chain.push(callback) unless callback in chain

    # Return the Entity object for easy chainability.
    this

  # If a `callback` is provided, removes the callback from an event.
  # Fails silently if no callback was found. If no `callback` is
  # provided, all callbacks attached to an event are removed.
  off: (event, callback = null) ->
    types(String, Optional(Function))
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
      hook.bind(@).call(this) for hook in @__fathom.events[event]

    # Return the Entity object for easy chainability.
    this

  die: () ->
    @.__fathom.entities.remove @

  # Returns an array of the groups this Entity is a member of.
  groups: () -> ["renderable", "updateable"]

  # Renders the Entity.
  render: (context) ->
    context.fillStyle = @color
    context.fillRect @x, @y, @width, @height

  # Returns true if this collides with other, else false.
  collides: (other) ->
    types Entity
    @.__fathom.uid != other.__fathom.uid and @touchingRect other

  # Updates the Entity.
  update: () ->

  # Returns the depth at which the Entity will be rendered (like Z-Ordering).
  # Can be reimplemented in a subclass.
  depth: () -> 0

class Tile extends Rect
  constructor: (@x, @y, @width, @type) ->
    super(@x, @y, @width)
    types(Number, Number, Number, Number)

    if @type == 0
      @color = new Color().randomizeRed(150, 255).toString()
    else if @type == 1
      @color = "#ff0"

  render: (context, dx, dy) ->
    context.fillStyle = @color

    context.fillRect @x + dx, @y + dy, @width, @height


# Generic health bar

class Bar extends Entity
  constructor: (@x, @y, @width=50, @fillColor="#0f0", @emptyColor="#f00") ->
    types(Number, Number, Optional(Number), Optional(String), Optional(String))

    @borderColor = "#000"
    @borderWidth = 1
    @height = 10

    @amt = 50
    @total = 100

    super @x, @y, @width, @height

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
    @on "pre-update", Fathom.BasicHooks.stickTo(@follow, 0, -10)

class Pixel
  constructor: (@r, @g, @b, @a) -> types(Number, Number, Number, Number)
  eq: (p) ->
    types(Pixel)
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
  constructor: (@widthInTiles, @heightInTiles, @tileSize) ->
    types(Number, Number, Number)
    super 0, 0, @widthInTiles * @tileSize, @heightInTiles * @tileSize

    @tiles = ((null for b in [0...@heightInTiles]) for a in [0...@widthInTiles])
    @data = undefined
    @corner = new Point(0, 0)

  setTile: (x, y, type) =>
    types(Number, Number, Number)
    @tiles[x][y] = new Tile(x * @tileSize, y * @tileSize, @tileSize, type)

  # Set the top right corner of the visible map.
  # TODO: This has a bad name. TODO and now it's even worse because it's a delta.
  setCorner: (diff) ->
    types(Vector)
    @corner.add(diff.multiply(@widthInTiles))

    for x in [0... @widthInTiles]
      for y in [0... @heightInTiles]
        if @data[@corner.x + x][@corner.y + y].eq(new Pixel(0, 0, 0, 255)) #TODO. Too specific.
          val = 1
        else
          val = 0

        @setTile(x, y, val)

  fromImage: (loc, corner, callback) ->
    types(String, Vector, Function)
    ready =>
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
    types(Rect)
    xStart = Math.floor(other.x/@tileSize)
    yStart = Math.floor(other.y/@tileSize)

    for x in [xStart..xStart+2]
      for y in [yStart..yStart+2]
        if 0 <= x < @widthInTiles and 0 <= y < @heightInTiles
          if @tiles[x][y].type == 1 and @tiles[x][y].touchingRect other
            return true

    return false

  render: (context) ->
    for tileX in [0...@widthInTiles]
      for tileY in [0...@heightInTiles]
        @tiles[tileX][tileY].render context, @x, @y

class StaticImage extends Entity
  constructor: (source, destination) ->
    super destination.x, destination.y, destination.size
    #TODO: Grab from file, use source etc

class Text extends Entity
  constructor: (@text, x=0, y=0, opts={}) ->
    types(String, Optional(Number), Optional(Number), Optional(Object))
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

class Camera extends Entity
  constructor: (args...) ->
    @dontAdjust = true
    super(args...)

  move: (x, y) ->
    @x = x
    @y = y

  groups: -> ["camera"]
  collides: -> false

  render: (entities, context, fn) ->
    for e in entities.get() when not e.dontAdjust
      e.x -= @x
      e.y -= @y

    entities.render context

    for e in entities.get() when not e.dontAdjust
      e.x += @x
      e.y += @y

class FollowCam extends Camera
  constructor: (@follow, rest...) -> super(rest...)
  update: -> Fathom.BasicHooks.slideTo(new Point(@follow.x - @width / 2, @follow.y - @height / 2)).bind(@)()
  groups: -> ["camera", "updateable"]
  snap: ->
    @x = @follow.x - @width / 2
    @y = @follow.y - @height / 2

class TextBox extends Text
  constructor: (text, x=0, y=0, @width=100, @height=-1, opts={}) ->
    types(String, Number, Number, Optional(Number), Optional(Number), Optional(Object))
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
  types(Function)
  if document.body then callback() else setTimeout (-> ready callback), 250

# TODO: This implementation is not complete.
fixedInterval = (fn, fps=24) ->
  types(Function, Optional(Number))
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
  types(Function, String)
  window_size = 500 #TODO

  ready () ->
    canv = document.createElement "canvas"
    canv.width = canv.height = window_size
    temp_context = canv.getContext('2d')

    Key.start()

    canv = document.getElementById canvasID
    context = canv.getContext('2d')

    cam = entities.get "camera"
    if cam.length > 1
      throw new Error("More than one camera.") #TODO: Camera#enable, Camera#disable
    if cam.length == 1
      cam = cam[0]


    wrappedLoop = () ->
      gameLoop context
      Tick.ticks += 1
      entities.update entities
      context.fillStyle = "#fff"
      context.fillRect 0, 0, 500, 500
      if cam
        cam.render entities, context
      else
        entities.render context

    fixedInterval wrappedLoop

# Export necessary things outside of closure.
@Fathom =
  Util       : Util
  Key        : Key
  Entity     : Entity
  Entities   : Entities
  Color      : Color
  Camera     : Camera
  FollowCam  : FollowCam
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
  Tick       : Tick

