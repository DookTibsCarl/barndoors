define([], () ->
  # may include things like desired mask dimensions, priority weight, etc.

  class SlidePair
    constructor: (@leftSlide, @rightSlide) ->

    toString: ->
      "\n\t#{@leftSlide}\n\t#{@rightSlide}"
      

  return SlidePair
)
