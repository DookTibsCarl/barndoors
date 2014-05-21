define(["model/model", "responsiveViewFactory" ], (Model, ResponsiveViewFactory) ->
  class BarnDoorController
    # constructor: (@targetDivName) ->
    constructor: () ->
      # set a local alias for jQuery
      # @$ = jq

    setup: (@configuration) ->
      # console.log "setup: there are #{@configuration.pairs.length} image pairs. Each image is #{@configuration.imageDimensions.width} pixels wide"
      console.log "setup with view factory..."

      @targetDivName = @configuration.targetDivName

      @appModel = Model.buildModelFromConfigurationObject(@configuration)
      # @appModel.debug()

      @viewFactory = new ResponsiveViewFactory()
      $(document).bind('screenSizeChanged', ((evt, data) =>
        @swapInView()
      ))
      @swapInView() # initial setup

      setTimeout((=> this.continueSlideshow()), @configuration.timeBetweenSlides)

    swapInView: () ->
      if @view?
        @view.pseudoDestructor()
        @view = null

      @view = @viewFactory.constructActiveView(@targetDivName, @appModel.imageWidth, @appModel.imageHeight)
      @view?.renderInitialView(@appModel.getActivePair())

    continueSlideshow: ->
      # console.log "continuing slideshow [#{this}]..."
      @appModel.advanceToNextPair()
      @view?.showNextPair(@appModel.getActivePair())
      setTimeout((=> this.continueSlideshow()), @configuration.timeBetweenSlides) # fat arrow ensures we bind to proper context (otherwise @ refers to window and not our class instance in the callback)

  return BarnDoorController
)
