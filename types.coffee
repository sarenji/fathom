# Type annotation for CoffeeScript/JavaScript.

getType = (someObj) ->
  funcNameRegex = /function (.+)\(/
  results = (funcNameRegex).exec((someObj).constructor.toString())
  results[1]

getSuperclasses = (obj) ->
  superclasses = []
  while true
    superclasses.push(getType(obj))

    if not obj.__proto__
      break
    obj = obj.__proto__

# slightly-better-than-js-typing

OUTER_ONLY = 0
EVERYTHING = 1
NEXT_FUNCTION = 2

#buildConstraint = (type, constraintfn) ->
#$string = new Constraint()

#TODO: Union types.
#TODO: Heterogenous tuples.
$string = (type = EVERYTHING) -> "string"
$number = (type = EVERYTHING) -> "number"
$object = (type = EVERYTHING) -> "object"
$function = (type = EVERYTHING) -> "function" #doing better function types seems very hard.

$ = (type) ->
  (how_deep) ->
    if how_deep == OUTER_ONLY
      "user type"
    else
      type

$array = (type) ->
  (how_deep) ->
    if how_deep == OUTER_ONLY
      "array"
    else if how_deep == NEXT_FUNCTION
      type
    else
      "array(#{type(EVERYTHING)})"

types = (typeList...) ->
  # Ascend the stack trace to get args of calling function.
  args = Array.prototype.slice.call types.caller.arguments

  throwError = (expected, received) ->
    err = "TypeError: got #{received}, expected #{expected} in #{types.caller}"

    console.log err
    throw "TypeError"

  if args.length != typeList.length
    console.log "Incorrect number of arguments. Got #{args.length}, expected #{typeList.length} in #{types.caller}"
    throw "ArgumentCountError"

  checkType = (type_given, object) ->
    if typeof object == "undefined"
      throw "YouUsedUndefinedYouMoronError"

    if typeof type_given == "string"
      good = getType(object) == type_given
      if not good
        throwError type_given, getType(object)
      return true

    switch type_given(OUTER_ONLY)
      when "string"
        if typeof object != "string"
          throwError type_given(true), typeof object
      when "number"
        if typeof object != "number"
          throwError type_given(true), typeof object
      when "object"
        if typeof object != "object"
          throwError type_given(true), typeof object
      when "function"
        if typeof object != "function"
          throwError type_given(true), typeof object
      when "array"
        good = (object.length == 0 or checkType(type_given(NEXT_FUNCTION), object[0]))

        if not good
          throwError type_given(EVERYTHING), typeof object
      when "user type"
        good = getSuperclasses(object).indexOf(type_given(EVERYTHING)) != -1
        if not good
          throwError "user type: #{type_given(EVERYTHING)}", getType(object)
      else
        throw "unknown type #{type_given(OUTER_ONLY)}"

    true

  for arg, i in args
    checkType(typeList[i], arg)
#Types = {$number: $number, $string: $string, $object: $object, $: $, $array: $array, types: types}

exports = (module?.exports or this)
exports.Types = {$ : $, $number: $number, $string : $string, $object : $object, $array : $array, $function : $function, types: types}
