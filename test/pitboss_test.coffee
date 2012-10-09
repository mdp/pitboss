assert = require 'assert'
pitboss = require('../src/pitboss')

describe "Running dubius code", ->
  beforeEach ->
    @options =
      ulimit: false
    @code = """
// EchoTron: returns the 'data' variable in a VM
if(typeof data == 'undefined') {
  var data = null
};
data
    """

  it "should take a JSON encodable message", (done) ->
    pitboss.create(code, @options)
    pitboss.run({})
    pitboss.on "end", (data) ->
      console.log data
      done()

  it "should return an JSON decoded message", (done) ->
    msg = {test:123}
    pitboss.create(code, @options)
    pitboss.run(msg)
    pitboss.on "end", (data) ->
      console.log data
      assert.equal data, msg
      done()
