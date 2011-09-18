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

exports = (if module isnt 'undefined' and module.exports then module.exports else this)
exports.Game = Game
exports.Entity