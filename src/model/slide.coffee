define([], () ->
  class Slide
    @SIDES = LEFT: "left", RIGHT: "right"

    constructor: (@side, @imgUrl, @label, @fontColor) ->
      # necessary to ensure that @side is legal?

    toString: ->
      "{side=#{@side}, url=#{@imgUrl}, label='#{@label}'}"

  return Slide
)
