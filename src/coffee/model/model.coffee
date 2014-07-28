define(["model/slide", "model/slidepair"], (Slide, SlidePair) ->
  # will include things like active pair index, pair ordering, etc.
  class Model
    # static convenience method - parses the passed in
    # config obj (or json, or whatever) and gives back
    # a fully fleshed out model
    @buildModelFromConfigurationObject: (configObj) ->
      pairs = []
      for pair in configObj.pairs
          leftProps = pair.left
          rightProps = pair.right
          leftSlide = new Slide(Slide.SIDES.LEFT, leftProps.images, leftProps.title, leftProps.details, leftProps.fontColor)
          rightSlide = new Slide(Slide.SIDES.RIGHT, rightProps.images, rightProps.title, rightProps.details, rightProps.fontColor)
          pair = new SlidePair(pair.pairId, pair.pairDescriptor, leftSlide, rightSlide)
          pairs.push pair

      model = new Model(pairs, configObj.imageDimensionData)
      model

    constructor: (@pairs, imageDimensionData) ->
      @activePairIndex = 0
      @imageDimensions = {}
      
      @defaultImageDimensionKey = null
      for dimensionKey, dimensions of imageDimensionData
        @imageDimensions[dimensionKey] = {
          width: dimensions.width
          height: dimensions.height
        }
        if (@defaultImageDimensionKey == null)
          @defaultImageDimensionKey = dimensionKey

    getAllAvailableImageDimensionTypes: () ->
      rv = []
      for key, val of @imageDimensions
        rv.push(key)
      rv

    getDimFromKey: (key = null) ->
      if (key == null)
        key = @defaultImageDimensionKey
      rv = @imageDimensions[key]
      if (rv == null or rv == undefined)
        console.log("ERROR - dimension key [" + key + "] was not found!!!")
      return rv

    ###
    getImageDimensionWidth: (key) ->
      return @getDimFromKey(key).width

    getImageDimensionHeight: (key) ->
      return @getDimFromKey(key).height
    ###

    getImageDimensionAspectRatio: (key) ->
      dim = @getDimFromKey(key)
      return dim.width / dim.height

    getActivePair: ->
      @pairs[@activePairIndex]

    getActivePairDescriptor: ->
      return @getActivePair().getPairDescriptor()

    getLookaheadPair: ->
      lookaheadIdx = @activePairIndex + 1
      if (lookaheadIdx >= @pairs.length)
        lookaheadIdx = 0
      @pairs[lookaheadIdx]
      

    getPairCount: ->
      @pairs.length

    advanceToPairIndex: (index) ->
      @activePairIndex = index

    advanceToNextPair: ->
      @activePairIndex = @getNextPairIndex()

    getNextPairIndex: ->
      rv = @activePairIndex + 1
      if (rv >= @pairs.length)
        rv = 0
      return rv

    getPrevPairIndex: ->
      rv = @activePairIndex - 1
      if (rv < 0)
        rv = @pairs.length - 1
      return rv

    ###
    debug: ->
      console.log "***** model with [#{@pairs.length}] pairs *****"
      for pair, i in @pairs
        console.log "[#{i}]: #{pair}"
        
      console.log "*********** done **************"
    ###

  return Model
)
