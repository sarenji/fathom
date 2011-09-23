{Fathom} = require "../fathom.js"

quickCheck = (fn, containerType, constraintFn) ->
  # get type information
  line = fn.toString().split("\n")[1]
  if line.indexOf("types") == -1
    line = fn.toString().split("\n")[2]

  throw "NoTypeInformationError" if line.indexOf("types") == -1

  types = line.split("(")[1].split(")")[0].split(",")
  types = (type.split('"')[1] for type in types)

  #types is now the list of arg types.


