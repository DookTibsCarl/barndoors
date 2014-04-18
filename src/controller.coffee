# define(["jquery", "js/app/slide", "js/app/slidepair", "js/app/model", "js/app/defaultview"], (jq, Slide, SlidePair, Model, DefaultView) ->
define(["jquery", "js/app/model", "js/app/defaultview"], (jq, Model, DefaultView) ->
  class BarnDoorController
    constructor: (@targetDivName) ->
      # set a local alias for jQuery
      # @$ = jq

    setup: (@configuration) ->
      console.log "setup: there are #{@configuration.pairs.length} image pairs. Each image is #{@configuration.imageDimensions.width} pixels wide"

      @appModel = Model.buildModelFromConfigurationObject(@configuration)
      # @appModel.debug()

      # in reality this should
      # 1. be getting pulled from some kind of method that knows about our current screen size / browser capabilities
      # 2. have some sort of defined interface that the controller can talk to (renderInitial, advanceToNext, etc.)
      # but this is just a prototype and will do for now
      @v = new DefaultView(@targetDivName, @appModel.imageWidth, @appModel.imageHeight)
      @v.renderInitialView(@appModel.getActivePair())

    slamShut: () ->
      @v.doSomethingCool()

       
  # finally, expose it
  return BarnDoorController
)
