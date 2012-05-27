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

  superclasses

# slightly-better-than-js-typing

OUTER_ONLY = 0
EVERYTHING = 1
NEXT_FUNCTION = 2

#buildConstraint = (type, constraintfn) ->
#$string = new Constraint()

#TODO: Union types.
#TODO: Heterogenous tuples.
#TODO: Rewrite this whole thing.
$string = (type = EVERYTHING) -> "string"
$number = (type = EVERYTHING) -> "number"
$object = (type = EVERYTHING) -> "object"
$function = (type = EVERYTHING) -> "function" #doing better function types seems very hard.
$optional = (type) ->
  (how_deep) ->
    if how_deep == OUTER_ONLY
      "optional"
    else if how_deep == NEXT_FUNCTION
      type
    else
      "optional(#{type(EVERYTHING)})"

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

throwError = (expected, received) ->
  err = "TypeError: got #{received}, expected #{expected} in #{types.caller}"

  console.log err
  throw new Error("TypeError")

validArgumentCount = (given, expected) ->
  lowCount = 0
  highCount = 0
  for type in expected
    highCount++
    lowCount++  if type(OUTER_ONLY) != "optional"

  return lowCount <= given.length <= highCount

types = (typeList...) ->

  # Ascend the stack trace to get args of calling function.
  args = Array.prototype.slice.call types.caller.arguments

  if not validArgumentCount(args, typeList)
    console.log "Incorrect number of arguments. Got #{args.length}, expected #{typeList.length} in #{types.caller}"
    console.trace()
    throw new Error("ArgumentCountError")

  # Replace all optional types in the type list with their non-optional
  # counterpart. Since we've ensured that the number of passed in arguments is
  # valid, we can now just loop through each extant argument and ensure it's
  # correct at this point.

  typeList = ((if t(OUTER_ONLY) == "optional" then t(NEXT_FUNCTION) else t) for t in typeList)

  checkType = (type_given, object) ->
    if typeof object == "undefined"
      console.trace()
      throw new Error("YouUsedUndefinedYouMoronError")

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
        throw new Error("unknown type #{type_given(OUTER_ONLY)}")

    true

  for arg, i in args
    checkType(typeList[i], arg)
#Types = {$number: $number, $string: $string, $object: $object, $: $, $array: $array, types: types}

exports = (module?.exports or this)
exports.Types = {$ : $, $optional: $optional, $number: $number, $string : $string, $object : $object, $array : $array, $function : $function, types: types}
