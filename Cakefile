fs = require 'fs'

{print} = require 'sys'
{spawn, exec} = require 'child_process'

build = (callback) ->
  coffee = spawn 'coffee', ['--map', '--compile', '--output', 'compiled/js', 'src/coffee']
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    callback?() if code is 0

# completely optional - generates a tags file for use with a tags-aware editor like vim.
# Requires Exuberant ctags and some entries in your ~/.ctags file to handle coffeescript, ex:
# 
# --langdef=coffee
# --langmap=coffee:.coffee
# --regex-coffee=/^[ \t]*class ([a-zA-Z_$][0-9a-zA-Z_$]*)([ \t]+extends.*)?/\1/c,class,classes/
# --regex-coffee=/^[ \t]*([a-zA-Z_$][0-9a-zA-Z_$]*):.*->.*/\1/f,function,functions/
# --regex-coffee=/^[ \t]*@([a-zA-Z_$][0-9a-zA-Z_$]*):.*->.*/\1/s,static,static methods/

task 'tags', 'uses Exuberant ctags to create tags file for use with editors like Vim', ->
  exec 'find . -name "*.coffee" | ctags -f coffeeTags -L -'

task 'build', 'compiles JavaScript and generates coffee->js sourcemaps, from src/coffee/ into compiled/js/', ->
  build()

# has to happen after a build. does Cakefile support dependencies?
# requires Node.js as currently written; could also do it with Java I believe
task 'optimize', 'creates optimized version of compiled javascript for release; creates js->minified sourcemap', ->
  nodeProc = spawn 'node', ['optimizer/lib/r.js', '-o', 'optimizer/build.js']
  nodeProc.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  nodeProc.stdout.on 'data', (data) ->
    print data.toString()

task 'clean', 'clean out and remove compiled/dist directories', ->
  try
    if fs.readdirSync('compiled/').length > 0
      exec 'rm -r compiled', (err) ->
        throw err if err

  try
    if fs.readdirSync('dist/').length > 0
      exec 'rm -r dist', (err) ->
        throw err if err

task 'release', 'does a complete clean/build/optimize cycle', ->
  invoke 'clean'
  build( () ->
    invoke 'optimize'
  )
