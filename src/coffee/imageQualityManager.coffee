define([], () ->

  class ImageQualityManager
    constructor: (@imageDimensionTypes) ->
      @logToConsole "constructing ImageQualityManager..."

    getImageTypeForRendering: () ->
      return "default"

    logToConsole: (s, prepend = true) ->
      if (prepend)
        console.log("ImageQualityManager::" + s)
      else
        console.log(s)

  return ImageQualityManager
)
