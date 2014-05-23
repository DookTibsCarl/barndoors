#!/usr/bin/env coffee

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
