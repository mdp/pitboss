assert = require 'assert'
{Runner} = require('../src/pitboss')
{Pitboss} = require('../src/pitboss')

describe "Pitboss running code", ->
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
    pitboss.run {data: "test"}, (err, result) ->
      assert.equal "test", result
    pitboss.run {data: 456}, (err, result) ->
      assert.equal 456, result
      done()

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
    pitboss = new Runner(@code)
    pitboss.run {data: 123}, (err, result) ->
      assert.equal 123, result
      done()

describe "Running infinite loop code", ->
  beforeEach ->
    @code = """
      if(typeof infinite != 'undefined' && infinite === true){
        while(true){"This is an never ending loop!"};
      }
      "OK"
    """

  it "should timeout and restart fork", (done) ->
    pitboss = new Runner @code,
      timeout: 100
    pitboss.run {infinite: true}, (err, result) ->
      assert.equal "Timedout", err
      pitboss.run {infinite: false}, (err, result) ->
        assert.equal "OK", result
        done()

  it "should happily allow for process failure (e.g. ulimit kills)", (done) ->
    pitboss = new Runner @code,
      timeout: 100
    pitboss.run {infinite: true}, (err, result) ->
      assert.equal "Process Failed", err
      pitboss.run {infinite: false}, (err, result) ->
        assert.equal "OK", result
        done()
    pitboss.proc.kill()
