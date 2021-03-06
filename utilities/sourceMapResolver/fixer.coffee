#!/usr/bin/env coffee

###

This is an attempt to take two varieties of sourcemap:

1. the (multiple) sourcemaps that take us from CoffeeScript to compiled JavaScript
2. the (single) sourcemap that takes us from compiled JavaScript files to the minified/concatenated/optimized JavaScript file


Back in index.html we can use the compiled individual JavaScript files like so:
  <script language="javascript" data-main="compiled/js/main" src="lib/js/require.js"></script>
and this will use map variety 1.

Or we can use the optimized Javascript like so:
  <script language="javascript" data-main="dist/barndoors-optimized" src="lib/js/require.js"></script>
and that will use map variety 2.

That's not bad; but what we *really* want is a way to go from the optimized thing we use in the browser back to 
the original CoffeeScript. This script is an attempt at doing that.

Couple of approaches below and some things are commented out. Idea is to look through one variety of sourcemap
and then the other, and attempt to do a translation and create a third source map. Eventual goal was to make this
generic but never got that far.

Current holdup is that the sourcemap generated by r.js (the optimizer that Require.js supports) appears to create
a map that has original column numbers of 0 everywhere. I think this is screwing things up - column 0 is enough
to get us to the right line while debugging, but is inaccurate for creating a translation between the two
types of maps. I think. Or maybe there's just a bug in here.

###

console.log "----- ATTEMPTING TO MERGE SOURCEMAPS -----"

# see https://github.com/mishoo/UglifyJS2/issues/145

resolveSourceMapSync = require("source-map-resolve").resolveSourceMapSync
SourceMapConsumer = require("source-map").SourceMapConsumer
SourceMapGenerator = require("source-map").SourceMapGenerator
fs = require('fs')
path = require('path')

# smg = new SourceMapGenerator({ file: "barndoors-optimized.js", sourceRoot: "../.." })
smg = new SourceMapGenerator({ file: "barndoors-optimized.js" })

loadDataForFile = (filePath) ->
  console.log "attempting load for [" + filePath + "]"
  fileContents = fs.readFileSync(filePath, { encoding: 'utf-8' })
  # fileBlob = { content: fileContents, path: filePath }

  srcMap = resolveSourceMapSync(fileContents, filePath, fs.readFileSync)
  if (srcMap)
    console.log "loaded the map: [" + srcMap.url + "]/[" + srcMap.sourceMappingURL + "]...file: [" + srcMap.map.file + "], sources [" + (if false then srcMap.map.sources else "skipped")+ "]"
    # console.log "mappings [" + srcMap.map.mappings + "]"

    smc = new SourceMapConsumer(srcMap.map)
    return { sourceMap: srcMap, consumer: smc }
  else
    console.log "unable to load the map for [" + filePath + "]..."
    return null

# load in the initial source map...
filePath = path.join(__dirname + '/../../dist/barndoors-optimized.js')
# filePath = path.join(__dirname + '/../../compiled/js/main.js')
blob = loadDataForFile(filePath)

jsToOptimizedConsumer = blob.consumer
jsToOptimizedMap = blob.sourceMap

console.log "\n\n....SHOW MAPPINGS...."
jsToOptimizedConsumer.eachMapping( (loopMapping) ->
  # console.log "[#{jsToOptimizedMap.map.file}.....source=[#{loopMapping.source}], genLine=[#{loopMapping.generatedLine}] genCol=[#{loopMapping.generatedColumn}], origLine=[#{loopMapping.originalLine}], origCol=[#{loopMapping.originalColumn}]"
  console.log JSON.stringify(loopMapping)
)

# now for each file mentioned in the original source map, load and parse its map
approachA = () ->
  for backFile in jsToOptimizedMap.map.sources
    backFilePath = path.join(__dirname + '/../../compiled/js/' + backFile)
    console.log "loading sub file [" + backFilePath + "]"

    subBlob = loadDataForFile(backFilePath)

    coffeeToJsConsumer = subBlob.consumer
    coffeeToJsMap = subBlob.sourceMap

    coffeeToJsConsumer.eachMapping( (loopMapping) ->
      posData = jsToOptimizedConsumer.generatedPositionFor({
        source: coffeeToJsMap.map.file
        line: loopMapping.generatedLine
        column: loopMapping.generatedColumn
      })

      console.log "[#{coffeeToJsMap.map.file}.....source=[#{loopMapping.source}], genLine=[#{loopMapping.generatedLine}] genCol=[#{loopMapping.generatedColumn}], origLine=[#{loopMapping.originalLine}], origCol=[#{loopMapping.originalColumn}]; breadcrumb to [" + posData.line + "]:[" + posData.column + "]"

      massagedPath = loopMapping.source
      massagedPath = massagedPath.replace("../..", "..")

      if (posData.line != null and posData.column != null) # why *are* these null sometimes?
        smg.addMapping({
          generated: {
            line: posData.line
            column: posData.column
          }
          # source: loopMapping.source
          source: massagedPath
          original: {
            line: loopMapping.originalLine
            column: loopMapping.originalColumn
          }
        })
      else
        console.log "null mapping?"

    )

approachB = () ->

  mapLoadedForFile = ""
  sm = null
  smc = null

  jsToOptimizedConsumer.eachMapping( (loopMapping) -> (
    backFilePath = path.join(__dirname + '/../../compiled/js/' + loopMapping.source)

    # console.log("[" + jsToOptimizedMap.map.file + "] mapping: " + JSON.stringify(loopMapping))

    if (mapLoadedForFile != backFilePath)
      console.log "LOADING THE MAP! [" + JSON.stringify(loopMapping) + "]"
      subBlob = loadDataForFile(backFilePath)

      sm = subBlob.sourceMap
      smc = subBlob.consumer

    fixedSource = "src/coffee/" + loopMapping.source.replace(".js", ".coffee")
    # console.log "fixed source [" + fixedSource + "]"

    posData = smc.originalPositionFor({
      source: fixedSource#loopMapping.source
      line: loopMapping.originalLine
      column: loopMapping.originalColumn
    })
    console.log "[#{jsToOptimizedMap.map.file}.....source=[#{loopMapping.source}], genLine=[#{loopMapping.generatedLine}] genCol=[#{loopMapping.generatedColumn}], origLine=[#{loopMapping.originalLine}], origCol=[#{loopMapping.originalColumn}]...breadcrumb to [" + posData.line + "]:[" + posData.column + "]"

    mapLoadedForFile = backFilePath
    return
  ) )

  ###
  posData = jsToOptimizedConsumer.generatedPositionFor({
    source: coffeeToJsMap.map.file
    line: loopMapping.generatedLine
    column: loopMapping.generatedColumn
  })
  ###
  

# approachA()
approachB()

# spit out what we end up with - this currently wipes out the previous map!
# console.log(smg.toString())
# fs.writeFileSync("../../dist/barndoors-optimized.js.map", smg.toString(), { encoding: 'utf-8' })



###
console.log("\n\n\nSANITY CHECK")

rawMap = {
  "version": 3,
  "file": "simpleton.js",
  "sourceRoot": "../..",
  "sources": [
    "src/coffee/simpleton.coffee"
  ],
  "names": [],
  "mappings": ";AAAA;AAAA,EAAA,MAAA,CAAO,CAAC,EAAD,CAAP,EAAa,SAAA,GAAA;AACX,QAAA,SAAA;AAAA,IAAM;6BACJ;;AAAA,0BAAA,WAAA,GAAa,SAAA,GAAA;AACX,QAAA,OAAO,CAAC,GAAR,CAAY,wBAAZ,CAAA,CAAA;AACA,eAAO,IAAP,CAFW;MAAA,CAAb,CAAA;;uBAAA;;QADF,CAAA;AAKA,WAAO,SAAP,CANW;EAAA,CAAb,CAAA,CAAA;AAAA"
}

smc = new SourceMapConsumer(rawMap)
smc.eachMapping( (loopMapping) ->
  console.log JSON.stringify(loopMapping)
)

# genPos = {line:1, column:148}
# origPos = smc.originalPositionFor(genPos)
# origPos = {line: 9, column: 21 }
# genPos = smc.generatedPositionFor(origPos)
# console.log "\n\nOriginal [" + JSON.stringify(origPos) + "] -> [" + JSON.stringify(genPos) + "] Generated"


mappings = rawMap.mappings
linesOfCode = mappings.split(";")
for lineOfCode, i in linesOfCode
  if (lineOfCode != "")
    segments = lineOfCode.split(",")
    for segment, k in segments
      console.log "line [" + i + "], segment [" + k + "] [" + segment + "]"
###
