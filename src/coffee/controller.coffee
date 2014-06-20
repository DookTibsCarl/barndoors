define(["model/model", "responsiveViewFactory" ], (Model, ResponsiveViewFactory) ->
  class BarnDoorController
    # constructor: (@targetDivName) ->
    constructor: () ->
      # set a local alias for jQuery
      # @$ = jq

      @autoplayTimeout = null
      $(document).on("jumpToSlideIndex", (evt) => (
        @handleJump(evt)
      ))

      $(document).on("toggleAutoplaySlideshow", (evt) => (
        @handleToggleAutoplay(evt)
      ))

    handleToggleAutoplay: (evt) ->
      if @isSlideshowPaused()
        # play - restart the slideshow with a shorter duration than usual
        @setNextSlideDelay(@configuration.timeBetweenSlides / 2)
      else
        # pause - stop the autoplay
        clearTimeout(@autoplayTimeout)
        @autoplayTimeout = null

      # either way we need to notify our views as some of them include an interface for play/pause
      @view?.updatePlayPauseStatus(not @isSlideshowPaused())

    handleJump: (evt) ->
      jumpIndex = evt.jumpIndex

      if (jumpIndex != @appModel.activePairIndex)
        @appModel.advanceToPairIndex(jumpIndex)
        @view?.showNextPair(@appModel.activePairIndex, @appModel.getActivePair())

        if not @isSlideshowPaused()
          @setNextSlideDelay(@configuration.timeBetweenSlides * 2)

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

      # @autoplayTimeout = setTimeout((=> this.continueSlideshow()), @configuration.timeBetweenSlides)
      @setNextSlideDelay()
      @view?.updatePlayPauseStatus(not @isSlideshowPaused())

    swapInView: () ->
      if @view?
        @view.pseudoDestructor()
        @view = null

      @view = @viewFactory.constructActiveView(this, @targetDivName, @appModel.imageWidth, @appModel.imageHeight)
      @view?.renderInitialView(@appModel.getActivePair())

    isSlideshowPaused: () ->
      return @autoplayTimeout == null

    pauseSlideshow: ->
      console.log "pausing slideshow"

    setNextSlideDelay: (delayTime = @configuration.timeBetweenSlides) ->
      if @autoplayTimeout != null
        clearTimeout(@autoplayTimeout)

      @autoplayTimeout = setTimeout((=> this.continueSlideshow()), delayTime)

    continueSlideshow: ->
      if @autoplayTimeout == null
        return

      # console.log "continuing slideshow [#{this}]..."
      @appModel.advanceToNextPair()
      
      @view?.showNextPair(@appModel.activePairIndex, @appModel.getActivePair())
      # @autoplayTimeout = setTimeout((=> this.continueSlideshow()), @configuration.timeBetweenSlides) # fat arrow ensures we bind to proper context (otherwise @ refers to window and not our class instance in the callback)
      @setNextSlideDelay()

  return BarnDoorController
)
