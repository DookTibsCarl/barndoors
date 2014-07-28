define([], () ->
  # may include things like desired mask dimensions, priority weight, etc.

  class SlidePair
    constructor: (@pairId, @pairDescriptor, @leftSlide, @rightSlide) ->

    getPairDescriptor: () ->
      return @pairDescriptor

    getPairId: () ->
      return @pairId

    toString: ->
      "\n\t#{@leftSlide}\n\t#{@rightSlide}"

    getAppropriateSlideImageUrls: (dimensionKey) ->
      return [@leftSlide.getImageUrl(dimensionKey), @rightSlide.getImageUrl(dimensionKey)]
      

  return SlidePair
)
