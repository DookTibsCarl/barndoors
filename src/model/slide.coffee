define([], () ->
  class Slide
    @SIDES = LEFT: "left", RIGHT: "right"

    constructor: (@side, @imgUrl, @title, @details, @fontColor) ->
      # necessary to ensure that @side is legal?

    toString: ->
      "{side=#{@side}, url=#{@imgUrl}, title='#{@title}'}"

  return Slide
)
