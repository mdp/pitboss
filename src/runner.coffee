vm = require 'vm'
util = require 'util'

script = null

if process.env['CODE']
  try
    script = vm.createScript(process.env['CODE'])
  catch err
    process.stderr.write "VM Syntax Error: #{err}"
    # Exit on syntax failure
    process.exit(1)
else
  process.stderr.write "Must pass in code via $CODE env variable"
  process.exit(2)

msg = ''
json = null
process.stdin.resume() # Start stdin to prevent exit
process.stdin.on 'data', (data) ->
  msg =  msg + data.toString()
  if msg[msg.length - 1] == '\n' # EOL
    result = null
    try
      json = JSON.parse(msg)
    catch err
      process.stderr.write("JSON Error: #{err}")
      process.exit(3)
    result = run(json)
    msg = ''
    json =  null
    process.stdout.write JSON.stringify(result || null)

run = (context) ->
  result = null
  try
    result = script.runInNewContext(context)
  catch err
    process.stderr.write "VM Runtime Error: #{err}"
  result
