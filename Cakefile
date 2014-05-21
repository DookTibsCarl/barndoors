fs = require 'fs'

{print} = require 'sys'
{spawn, exec} = require 'child_process'

build = (callback) ->
  # coffee = spawn 'coffee', ['--map', '--compile', '--output', 'dist/js', 'src/js/*'] # do it this way to compile everything into a single dir
  coffee = spawn 'coffee', ['--map', '--compile', '--output', 'dist/js', 'src/coffee'] # do it this way to preserve directory structure among compiled files
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    callback?() if code is 0

# completley optional - generates a tags file for use with a tags-aware editor like vim.
# Requires Exuberant ctags and some entries in your ~/.ctags file to handle coffeescript, ex:
# 
# --langdef=coffee
# --langmap=coffee:.coffee
# --regex-coffee=/^[ \t]*class ([a-zA-Z_$][0-9a-zA-Z_$]*)([ \t]+extends.*)?/\1/c,class,classes/
# --regex-coffee=/^[ \t]*([a-zA-Z_$][0-9a-zA-Z_$]*):.*->.*/\1/f,function,functions/
# --regex-coffee=/^[ \t]*@([a-zA-Z_$][0-9a-zA-Z_$]*):.*->.*/\1/s,static,static methods/

task 'tags', 'create tags file', ->
  exec 'find . -name "*.coffee" | ctags -f coffeeTags -L -'

task 'build', 'Build js/lib/ from src/', ->
  build()

# has to happen after a build
task 'optimize', 'NOT YET WORKING: creates optimized version of package for release; requires Node.js', ->
  nodeProc = spawn 'node', ['optimizer/lib/r.js', '-o', 'optimizer/build.js']
  nodeProc.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  nodeProc.stdout.on 'data', (data) ->
    print data.toString()

task 'clean', 'clean out and removed compiled dist directory', ->
  if fs.readdirSync('lib/').length > 0
    exec 'rm -r dist', (err) ->
      throw err if err
