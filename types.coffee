# Type annotation for CoffeeScript/JavaScript.
#
# Examples:
#
# types(Number, String)
# types(Array(Number))
# types(Array)
# types(Number, Optional(Object))
#
types = (typeList...) ->
  # Ascend the stack trace to get args of calling function.
  calledWith = (callerArg  for callerArg in types.caller.arguments)

  # Get min and max number of arguments
  [minArgs, maxArgs] = [0, typeList.length]
  minArgs++  for type in typeList when type not instanceof Optional

  # Validate argument length
  actualLength = calledWith.length
  if actualLength < minArgs || actualLength > maxArgs
    range = if minArgs == maxArgs then minArgs else "#{minArgs} - #{maxArgs}"
    throw new Error("Expected #{range} argument(s), got #{actualLength}")

  # Iterate through each type provided
  for _, i in calledWith
    type = typeList[i]

    # Unwrap optional types, if applicable
    if type instanceof Optional
      type = type.unwrappedType

    # Validate types
    checkType(type, calledWith[i])

checkType = (type, calledWith) ->
  # TODO: Handle heterogenous optional types.
  # Handle primitive types
  switch typeof calledWith
    when 'number'
      throwError(type, "Number")  unless type == Number
    when 'string'
      throwError(type, "String")  unless type == String
    when 'boolean'
      throwError(type, "Boolean")  unless type == Boolean
    else
      if calledWith instanceof Array
        return  if type == Array
        if type not instanceof Array
          # `type` and `calledWith` don't match, so we want to error.
          throwError(type, "Array")
        else
          # Check type of all elements inside the calledWith array
          subtype = type[0]
          for _, i in calledWith
            checkType(subtype, calledWith[i])
      else
        throwError(type, calledWith.name)  unless calledWith instanceof type

throwError = (expected, actual) ->
  throw new Error("Expected #{expected}, got #{actual}.")

Optional = (type) ->
  if this not instanceof Optional
    return new Optional(type)
  @unwrappedType = type
  return

@Types = {types, Optional}
