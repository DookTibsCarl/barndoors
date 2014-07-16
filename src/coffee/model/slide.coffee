define([], () ->
  class Slide
    @SIDES = LEFT: "left", RIGHT: "right"

    constructor: (@side, urlData, @title, @details, @fontColor) ->
      # necessary to ensure that @side is legal?
      @imgUrls = {}

      for imgKey, imgVal of urlData
        @imgUrls[imgKey] = imgVal

    getImageUrl: (key) ->
      rv = @imgUrls[key]
      if rv == null or rv == undefined
        console.log "ERROR - image key [" + key + "] was not found on this slide!"
      return rv

    toString: ->
      "{side=#{@side}, url=#{@imgUrls}, title='#{@title}'}"

  return Slide
)
