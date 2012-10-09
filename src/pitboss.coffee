vm =  require 'vm'
exports.create = (code, options) ->
  script = vm.createScript(code)
  run: (msg) ->
    script.run(msg)


