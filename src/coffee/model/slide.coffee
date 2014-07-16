define([], () ->
  class Slide
    @SIDES = LEFT: "left", RIGHT: "right"

    constructor: (@side, urlData, @title, @details, @fontColor) ->
      # necessary to ensure that @side is legal?
      @imgUrls = {}

      for imgKey, imgVal of urlData
        @imgUrls[imgKey] = imgVal

    getImageUrl: (key) ->
      return @imgUrls[key]

    toString: ->
      "{side=#{@side}, url=#{@imgUrl}, title='#{@title}'}"

  return Slide
)
