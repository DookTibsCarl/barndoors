define([], () ->
  class ImageQualityManager
    # these values should correspond to the ones used in the configuration JSON passed to this widget
    STRATEGY_DEFAULT = "default"
    STRATEGY_HIRES = "hires"

    constructor: (@imageDimensionTypes) ->
      @logToConsole "constructing ImageQualityManager..."
      # @currentStrategy = @imageDimensionTypes[0]

      if (not @switchToStrategyIfValid(STRATEGY_DEFAULT))
        @switchToStrategyIfValid(@imageDimensionTypes[0])

      @logToConsole "established [" + @currentStrategy + "] as quality to use..."
      $("#debugImageStrategy").html(@currentStrategy)

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
