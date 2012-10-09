{fork} = require 'child_process'
{EventEmitter}  = require 'events'

module.exports = class Pitboss extends EventEmitter
  constructor: (@code) ->
    @runner = fork('./lib/runner.js')
    @runner.send JSON.stringify({code:@code})
    @runner.on 'message', @messageHandler
    @callbacks = {}

  run: (context, callback) ->
    id = Date.now().toString() + Math.floor(Math.random() * 1000)
    msg =
      context: context
      id: id
    if callback
      @callbacks[id] = callback
    @runner.send JSON.stringify msg

  messageHandler: (json) =>
    msg = JSON.parse(json)
    @emit msg.result
    if @callbacks[msg.id]
      @callbacks[msg.id](msg.result)
      delete @callbacks[msg.id]

