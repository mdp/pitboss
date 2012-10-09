assert = require 'assert'
{fork} = require 'child_process'

describe "Running dubious code", ->
  beforeEach ->
    @code = """
// EchoTron: returns the 'data' variable in a VM
if(typeof data == "undefined") {
  var data = null
};
data
    """

  it "run without errors", (done) ->
    runner = fork('./lib/runner.js')
    runner.on 'message', (data) ->
      msg = JSON.parse(data)
      assert.equal(msg.id, "123")
      assert.equal(msg.result, null)
      done()
    runner.send(JSON.stringify({code: @code})) # Setup
    runner.send(JSON.stringify({id: "123", context:{}})) # Setup

describe "Running code that assumes priviledge", ->
  beforeEach ->
    @code = """
require('http');
123;
    """

  it "should fail on require", (done) ->
    runner = fork('./lib/runner.js')
    runner.on 'message', (data) ->
      msg = JSON.parse(data)
      assert.equal(msg.id, "123")
      assert.equal(msg.result, null)
      assert.equal(msg.error, "VM Runtime Error: ReferenceError: require is not defined")
      done()
    runner.send(JSON.stringify({code: @code})) # Setup
    runner.send(JSON.stringify({id: "123", context:{}})) # Setup

describe "Running code that uses Buffer", ->
  beforeEach ->
    @code = """
var buf = new Buffer();
123;
    """

  it "should fail on require", (done) ->
    runner = fork('./lib/runner.js')
    runner.on 'message', (data) ->
      msg = JSON.parse(data)
      assert.equal(msg.id, "123")
      assert.equal(msg.result, null)
      assert.equal(msg.error, "VM Runtime Error: ReferenceError: Buffer is not defined")
      done()
    runner.send(JSON.stringify({code: @code})) # Setup
    runner.send(JSON.stringify({id: "123", context:{}})) # Setup

describe "Running shitty code", ->
  beforeEach ->
    @code = """
This isn't even Javascript!!!!
    """

  # We can't even run this code, so we return an error immediately on run
  it "should return errors on running of bad syntax code", (done) ->
    runner = fork('./lib/runner.js')
    runner.on 'message', (data) ->
      msg = JSON.parse(data)
      assert.equal(msg.id, "123")
      assert.equal(msg.result, undefined)
      assert.equal(msg.error, "VM Syntax Error: SyntaxError: Unexpected identifier")
      done()
    runner.send(JSON.stringify({code: @code})) # Setup
    runner.send(JSON.stringify({id: "123", context:{}})) # Setup

describe "Running runtime error code", ->
  beforeEach ->
    @code = """
var foo = [];
foo[data][123];
    """

  it "should happily suck up and relay the errors", (done) ->
    runner = fork('./lib/runner.js')
    runner.on 'message', (data) ->
      msg = JSON.parse(data)
      assert.equal(msg.id, "123")
      assert.equal(msg.result, undefined)
      assert.equal(msg.error, "VM Runtime Error: TypeError: Cannot read property '123' of undefined")
      done()
    runner.send(JSON.stringify({code: @code})) # Setup
    runner.send(JSON.stringify({id: "123", context:{data:'foo'}})) # Setup

