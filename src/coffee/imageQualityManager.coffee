define([], () ->
  class ImageQualityManager
    # these values should correspond to the ones used in the configuration JSON passed to this widget
    STRATEGY_DEFAULT = "default"
    STRATEGY_RETINA = "retina"
    # STRATEGY_LOW_RES = "lowres"

    RETINA_PIXEL_RATIO_THRESHOLD = 2

    constructor: (@imageDimensionTypes) ->
      @logToConsole "constructing ImageQualityManager..."
      # @currentStrategy = @imageDimensionTypes[0]

      @dpr = window.devicePixelRatio
      $("#debugDevicePixelRatio").html(@dpr)

      # choose the current strategy - retina or default?
      @currentStrategy = null
      if (@dpr >= RETINA_PIXEL_RATIO_THRESHOLD)
        if (not @switchToStrategyIfValid(STRATEGY_RETINA))
          @switchToStrategyIfValid(STRATEGY_DEFAULT)
      else
        @switchToStrategyIfValid(STRATEGY_DEFAULT)

      if @currentStrategy == null
        @switchToStrategyIfValid(@imageDimensionTypes[0])

      @logToConsole "established [" + @currentStrategy + "] as quality to use..."
      $("#debugImageStrategy").html(@currentStrategy)

      $("#debugImageQualityManager").html("Device Pixel Ratio [" + @dpr + "], threshold [" + RETINA_PIXEL_RATIO_THRESHOLD + "], strategy to use [" + @currentStrategy + "]")

    switchToStrategyIfValid: (strat) ->
      if (strat in @imageDimensionTypes)
        @currentStrategy = strat
        return true
      else
        @logToConsole("[" + strat + "] is not a valid strategy given the current configuration!")
        return false

    getImageTypeForRendering: () ->
      return @currentStrategy

    logToConsole: (s, prepend = true) ->
      console.log("ImageQualityManager::" + s)

  return ImageQualityManager
)
