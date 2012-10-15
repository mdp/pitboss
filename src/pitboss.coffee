{fork} = require 'child_process'
{EventEmitter}  = require 'events'

exports.Pitboss = class Pitboss extends EventEmitter
  constructor: (code, options) ->
    @runner = new Runner(code, options)
    @runner.on 'completed', =>
      @next()
    @q = []

  run: (context, callback) ->
    @q.push({context:context,callback:callback})
    @next()

  next: ->
    return false if @runner.running
    c = @q.shift()
    if c
      @runner.run(c.context, c.callback)

# Can only run one at a time due to the blocking nature of VM
# Need to queue this up outside of the process since it's over an async channel
exports.Runner = class Runner extends EventEmitter
  constructor: (@code, @options) ->
    @options ||= {}
    @options.timeout ||= 500
    @launchFork()
    @running = false
    @callback = null

  launchFork: ->
    @proc = fork('./lib/forkable.js')
    @proc.on 'message', @messageHandler
    @proc.on 'exit', @failedForkHandler
    @proc.send {code:@code}

  run: (context, callback) ->
    return false if @running
    id = Date.now().toString() + Math.floor(Math.random() * 1000)
    msg =
      context: context
      id: id
    @callback = callback || false
    @startTimer()
    @running = id
    @proc.send msg
    id

  disconnect: ->
    @proc.disconnect() if @proc and @proc.connected

  kill: ->
    @proc.kill("SIGKILL") if @proc and @proc.connected

  messageHandler: (msg) =>
    @running = false
    @closeTimer()
    @emit 'result', msg
    if @callback
      @callback(null, msg.result)
    @notifyCompleted()

  failedForkHandler: =>
    @running = false
    @closeTimer(@timer)
    @launchFork()
    error = @currentError || "Process Failed"
    @emit 'failed', error
    @callback(error) if @callback
    @notifyCompleted()

  timeout: =>
    @currentError = "Timedout"
    @kill()

  notifyCompleted: ->
    @emit 'completed'

  startTimer: ->
    @closeTimer()
    @timer = setTimeout(@timeout, @options['timeout'])

  closeTimer: ->
    clearTimeout(@timer) if @timer

