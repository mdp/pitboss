assert = require 'assert'
utils = require '../src/utilities'
{spawn} = require 'child_process'

describe "Running dubius code", ->
  beforeEach ->
    @code = """
// EchoTron: returns the 'data' variable in a VM
if(typeof data == "undefined") {
  var data = null
};
data
    """

  it "run without errors", (done) ->
    cmd = "./node_modules/coffee-script/bin/coffee"
    args = ["./src/runner.coffee"]
    env = utils.clone process.env
    env["CODE"] = @code
    runner = spawn cmd, args,
      cwd: process.cwd()
      env: env
    runner.stdin.write('{}\n')
    runner.on 'exit', (code) ->
      assert(false, "Should not exit prematurely")
    runner.stderr.on 'data', (data) ->
      console.log data.toString()
      assert(false, "Should not result in an stderr data")
    runner.stdout.on 'data', (data) ->
      assert.equal(data.toString(), "null")
      done()

  it "should get back the result", (done) ->
    cmd = "./node_modules/coffee-script/bin/coffee"
    args = ["./src/runner.coffee"]
    env = utils.clone process.env
    env["CODE"] = @code
    runner = spawn cmd, args,
      cwd: process.cwd()
      env: env
    runner.stderr.on 'data', (data) ->
      console.log data.toString()
    runner.stdin.write('{"data":123}\n')
    runner.stdout.on 'data', (data) ->
      if data.toString() == '123'
        runner.stdin.write('{"data":456}\n')
      else
        done()

describe "Running shitty code", ->
  beforeEach ->
    @code = """
This isn't even Javascript!!!!
    """

  # We can't even run this code, so we exit
  it "should exit on bad syntax errors", (done) ->
    cmd = "./node_modules/coffee-script/bin/coffee"
    args = ["./src/runner.coffee"]
    env = utils.clone process.env
    env["CODE"] = @code
    runner = spawn cmd, args,
      cwd: process.cwd()
      env: env
    runner.stdin.write('{}\n')
    runner.on 'exit', (code) ->
      assert.equal(code, 1)
    runner.stderr.on 'data', (data) ->
      assert.ok(data)
      done()

describe "Running runtime error code", ->
  beforeEach ->
    @code = """
var foo = [];
foo[data][123];
    """

  it "should happily suck up and relay the errors", (done) ->
    cmd = "./node_modules/coffee-script/bin/coffee"
    args = ["./src/runner.coffee"]
    env = utils.clone process.env
    env["CODE"] = @code
    runner = spawn cmd, args,
      cwd: process.cwd()
      env: env
    runner.stdin.write('{"data":123}\n')
    runner.on 'exit', (code) ->
      assert(false, "Should not exit prematurely")
    runner.stderr.on 'data', (data) ->
      console.log data.toString()
      done()
    runner.stdout.on 'data', (data) ->
      console.log data.toString()
