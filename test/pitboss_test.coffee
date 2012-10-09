assert = require 'assert'
Pitboss = require('../src/pitboss')

describe "Running dubius code", ->
  beforeEach ->
    @code = """
// EchoTron: returns the 'data' variable in a VM
if(typeof data == 'undefined') {
  var data = null
};
data
    """

  it "should take a JSON encodable message", (done) ->
    pitboss = new Pitboss(@code)
    pitboss.run {data: 123}, (result) ->
      assert.equal 123, result
      done()
