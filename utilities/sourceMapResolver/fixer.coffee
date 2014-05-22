#!/usr/bin/env coffee

# see https://github.com/mishoo/UglifyJS2/issues/145

resolveSourceMapSync = require("source-map-resolve").resolveSourceMapSync
SourceMapConsumer = require("source-map").SourceMapConsumer
SourceMapGenerator = require("source-map").SourceMapGenerator
fs = require('fs')
path = require('path')

# smg = new SourceMapGenerator({ file: "barndoors-optimized.js", sourceRoot: "../.." })
smg = new SourceMapGenerator({ file: "barndoors-optimized.js" })

loadDataForFile = (filePath) ->
  # console.log "attempting load for [" + filePath + "]"
  fileContents = fs.readFileSync(filePath, { encoding: 'utf-8' })
  fileBlob = { content: fileContents, path: filePath }

  srcMap = resolveSourceMapSync(fileContents, filePath, fs.readFileSync)
  if (srcMap)
    # console.log "loaded the map: [" + srcMap.url + "]/[" + srcMap.sourceMappingURL + "]...file: [" + srcMap.map.file + "], sources [" + (if false then srcMap.map.sources else "skipped")+ "]"
    # console.log "mappings [" + srcMap.map.mappings + "]"

    smc = new SourceMapConsumer(srcMap.map)
    return { sourceMap: srcMap, consumer: smc }
  else
    console.log "unable to load the map for [" + filePath + "]..."
    return null

# load in the initial source map...
filePath = path.join(__dirname + '/../../dist/barndoors-optimized.js')
blob = loadDataForFile(filePath)

jsToOptConsumer = blob.consumer
jsToOptMap = blob.sourceMap

###
jsToOptConsumer.eachMapping( (loopMapping) ->
  console.log "[#{jsToOptMap.map.file}.....source=[#{loopMapping.source}], genLine=[#{loopMapping.generatedLine}] genCol=[#{loopMapping.generatedColumn}], origLine=[#{loopMapping.originalLine}], origCol=[#{loopMapping.originalColumn}]"
)
###

# now for each file mentioned in the original source map, load and parse its map
for backFile in jsToOptMap.map.sources
  backFilePath = path.join(__dirname + '/../../compiled/js/' + backFile)
  subBlob = loadDataForFile(backFilePath)

  coffeeToJsConsumer = subBlob.consumer
  coffeeToJsMap = subBlob.sourceMap

  coffeeToJsConsumer.eachMapping( (loopMapping) ->
    posData = jsToOptConsumer.generatedPositionFor({
      source: coffeeToJsMap.map.file
      line: loopMapping.generatedLine
      column: loopMapping.generatedColumn
    })

    # console.log "[#{coffeeToJsMap.map.file}.....source=[#{loopMapping.source}], genLine=[#{loopMapping.generatedLine}] genCol=[#{loopMapping.generatedColumn}], origLine=[#{loopMapping.originalLine}], origCol=[#{loopMapping.originalColumn}]; breadcrumb to [" + posData.line + "]:[" + posData.column + "]"

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

# spit out what we end up with - this currently wipes out the previous map!
# console.log(smg.toString())
# fs.writeFileSync("../../dist/barndoors-optimized.js.map", smg.toString(), { encoding: 'utf-8' })
