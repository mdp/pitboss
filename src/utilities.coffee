exports.clone = (object, filter) ->
  Object.keys(object).reduce (if filter then (obj, k) ->
    obj[k] = object[k]  if filter(k)
    obj
   else (obj, k) ->
    obj[k] = object[k]
    obj
  ), {}
