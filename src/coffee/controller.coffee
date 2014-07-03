define(["model/model", "responsiveViewFactory", "imageLoader" ], (Model, ResponsiveViewFactory, ImageLoader) ->
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

    logToConsole: (s) ->
      console.log("BarnDoorController::" + s)

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
      clearTimeout(@autoplayTimeout) # turn off autoplay in case it finishes before the preload does

      if (jumpIndex != @appModel.activePairIndex)
        oldIndex = @appModel.activePairIndex

        @appModel.advanceToPairIndex(jumpIndex)

        activePair = @appModel.getActivePair()
        @imageLoader.ensureImagesLoaded([activePair.leftSlide.imgUrl, activePair.rightSlide.imgUrl], ( =>
          updatedIndex = @appModel.activePairIndex
          @view?.showNextPair(updatedIndex, activePair, updatedIndex < oldIndex)
          @preloadNextPair()

          if not @isSlideshowPaused()
            @setNextSlideDelay(@configuration.timeBetweenSlides * 2)
        ))


    setup: (@configuration) ->
      # @logToConsole "setup: there are #{@configuration.pairs.length} image pairs. Each image is #{@configuration.imageDimensions.width} pixels wide"
      @logToConsole "setup with view factory..."

      @targetDivName = @configuration.targetDivName

      @appModel = Model.buildModelFromConfigurationObject(@configuration)
      # @appModel.debug()

      @imageLoader = new ImageLoader()

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

      activePair = @appModel.getActivePair()
      @logToConsole "new preload approach..."
      @imageLoader.ensureImagesLoaded([activePair.leftSlide.imgUrl, activePair.rightSlide.imgUrl], ( =>
        @logToConsole "callback firing!"
        @view?.renderInitialView(@appModel.getActivePair())

        @preloadNextPair()
      ))

    # loads the next set of images. No callback / fire and forget. If it hasn't finished by the time the n
    preloadNextPair: () ->
      @logToConsole "disabling lookahead preload"
      return

      peekPair = @appModel.getLookaheadPair()
      @imageLoader.ensureImagesLoaded([peekPair.leftSlide.imgUrl, peekPair.rightSlide.imgUrl])

      ###
      # simulate multiple preload requests with competing callbacks - does the cleanup functionality in "setupCallbacks" work right?
      @imageLoader.ensureImagesLoaded([peekPair.leftSlide.imgUrl, peekPair.rightSlide.imgUrl], ( =>
        @logToConsole "WE SHOULD NEVER SEE THIS - NEXT CALLBACK SHOULD OVERWRITE IT!"
      ))
      @imageLoader.ensureImagesLoaded([peekPair.leftSlide.imgUrl, peekPair.rightSlide.imgUrl], ( =>
        @logToConsole "FAST FAST!"
      ))
      ###

    isSlideshowPaused: () ->
      return @autoplayTimeout == null

    pauseSlideshow: ->
      @logToConsole "pausing slideshow"

    setNextSlideDelay: (delayTime = @configuration.timeBetweenSlides) ->
      if @autoplayTimeout != null
        clearTimeout(@autoplayTimeout)

      @autoplayTimeout = setTimeout((=> this.continueSlideshow()), delayTime)

    continueSlideshow: ->
      if @autoplayTimeout == null
        return

      # @logToConsole "continuing slideshow [#{this}]..."
      @appModel.advanceToNextPair()
      
      # old way - tell the view to show the next pair and immediately restart the counter. problem is this was causing
      # @view?.showNextPair(@appModel.activePairIndex, @appModel.getActivePair())
      # @setNextSlideDelay()

      @logToConsole "---------------------"
      @logToConsole "---------------------"
      @logToConsole "---------------------"

      activePair = @appModel.getActivePair()
      @imageLoader.ensureImagesLoaded([activePair.leftSlide.imgUrl, activePair.rightSlide.imgUrl], ( =>
        @view?.showNextPair(@appModel.activePairIndex, activePair)
        @preloadNextPair()
        @setNextSlideDelay()
      ))

  return BarnDoorController
)
