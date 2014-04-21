define(["js/app/slide", "js/app/slidepair"], (Slide, SlidePair) ->
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
          leftSlide = new Slide(Slide.SIDES.LEFT, leftProps.image, leftProps.title, leftProps.details, leftProps.fontColor)
          rightSlide = new Slide(Slide.SIDES.RIGHT, rightProps.image, rightProps.title, rightProps.details, rightProps.fontColor)
          pair = new SlidePair(leftSlide, rightSlide)
          pairs.push pair

      model = new Model(pairs, configObj.imageDimensions.width, configObj.imageDimensions.height)
      model
      

    constructor: (@pairs, @imageWidth, @imageHeight) ->
      @activePairIndex = 0

    getActivePair: ->
      @pairs[@activePairIndex]

    advanceToNextPair: ->
      @activePairIndex++
      if (@activePairIndex >= @pairs.length)
        @activePairIndex = 0

    debug: ->
      console.log "###### model with [#{@pairs.length}] pairs #####"
      console.log "imageWidth: [#{@imageWidth}]"
      console.log "imageHeight: [#{@imageHeight}]"
      for pair, i in @pairs
        console.log "[#{i}]: #{pair}"
        
      console.log "############## done ##########"

  return Model
)
