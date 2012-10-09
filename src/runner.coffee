vm = require 'vm'
util = require 'util'

script = null
errorStatus = 0
errorStatusMsg = null
STATUS =
  'FATAL': 1

process.on 'message', (json) ->
  try
    msg = JSON.parse(json)
    parseMessage(msg)
  catch err
    error("JSON Error: #{err}")
    return false

parseMessage = (msg) ->
  if msg['code']
    create(msg['code'])
  else
    run(msg)

create = (code) ->
  try
    script = vm.createScript(code)
  catch err
    # Fatal, never try again
    errorStatus = STATUS['FATAL']
    errorStatusMsg = "VM Syntax Error: #{err}"

run = (msg) ->
  if isFatalError()
    error errorStatusMsg, msg.id
    return false
  unless script
    error "Code not setup: #{err}"
    return false
  try
    res =
      result: script.runInNewContext(msg.context || {}) || null # script can return undefined, ensure it's null
      id: msg.id
    message(res)
  catch err
    error "VM Runtime Error: #{err}", msg.id

isFatalError = ->
  if errorStatus == STATUS['FATAL']
    true
  else
    false

error = (msg, id) ->
  id ||= null
  message
    error: msg
    id: id

message = (msg) ->
  process.send JSON.stringify(msg)
