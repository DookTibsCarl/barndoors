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
        if (key == "default")
          console.log "ERROR - image key [" + key + "] was not found on this slide!"
        else
          console.log "WARNING - image key [" + key + "] was not found for this slide; trying default instead"
          rv = @getImageUrl("default")

      return rv

    toString: ->
      "{side=#{@side}, url=#{@imgUrls}, title='#{@title}'}"

  return Slide
)
