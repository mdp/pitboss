vm = require 'vm'
util = require 'util'

script = null
errorStatus = 0
errorStatusMsg = null
STATUS =
  'FATAL': 1

process.on 'message', (msg) ->
  if msg['code']
    create(msg['code'])
  else
    run(msg)

create = (code) ->
  code = "\"use strict\";\n#{code}"
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
    error "No code to run"
    return false

  msg.context ?= {}

  if msg?.libraries
    if Array.isArray msg?.libraries
      for lib in msg?.libraries
        msg.context[lib] = require lib
    else if typeof(msg?.libraries)
      for varName, lib of msg?.libraries
        msg.context[varName] = require lib
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
  process.send msg
