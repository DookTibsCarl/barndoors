define(["model/model", "responsiveViewFactory", "imageLoader", "imageQualityManager", "cookieUtils" ], (Model, ResponsiveViewFactory, ImageLoader, ImageQualityManager, CookieUtils) ->
  class BarnDoorController
    AUTOPLAY_COOKIE_NAME = "barndoor_homepage_autoplay"
    # constructor: (@targetDivName) ->
    constructor: () ->
      # set a local alias for jQuery
      # @$ = jq

      console.log "Setting Jquery interval to 50..."
      jQuery.fx.interval = 50

      @autoplayTimeout = null
      $(document).on("jumpToSlideIndex", (evt) => (
        @handleJump(evt.jumpIndex)
      ))

      $(document).on("moveToNextSlideIndex", (evt) => (
        $.event.trigger({ type: "ga_barndoorMovingToNewPair" })
        @handleJump(@appModel.getNextPairIndex(), 1)
      ))

      $(document).on("moveToPrevSlideIndex", (evt) => (
        $.event.trigger({ type: "ga_barndoorMovingToNewPair" })
        @handleJump(@appModel.getPrevPairIndex(), -1)
        # @view.checkFontHeights()
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
        if (evt.updateAutoplayCookie != null and evt.updateAutoplayCookie == "true")
          CookieUtils.eraseCookie(AUTOPLAY_COOKIE_NAME)
      else
        # pause - stop the autoplay
        clearTimeout(@autoplayTimeout)
        @autoplayTimeout = null
        if (evt.updateAutoplayCookie != null and evt.updateAutoplayCookie == "true")
          CookieUtils.createCookie(AUTOPLAY_COOKIE_NAME, "false", CookieUtils.createExpiryTimeInDays(20 * 365)) # expire in 20 years

      # either way we need to notify our views as some of them include an interface for play/pause
      @view?.updatePlayPauseStatus(not @isSlideshowPaused())

    handleJump: (jumpIndex, forceForwardOrBackward = 0) ->
      clearTimeout(@autoplayTimeout) # turn off autoplay in case it finishes before the preload does

      if (jumpIndex != @appModel.activePairIndex)
        oldIndex = @appModel.activePairIndex

        @appModel.advanceToPairIndex(jumpIndex)

        activePair = @appModel.getActivePair()
        @imageLoader.ensureImagesLoaded(@getCorrectImageUrlsForPair(activePair), ( =>
          updatedIndex = @appModel.activePairIndex

          if (forceForwardOrBackward == 0)
            reverseAnim = updatedIndex < oldIndex
          else
            reverseAnim = forceForwardOrBackward == -1


          @view?.showNextPair(updatedIndex, activePair, reverseAnim)
          @googleAnalyticsSpan.html(@appModel.getActivePairAndNeighborsDescriptor())
          @preloadNextPair()

          if not @isSlideshowPaused()
            @setNextSlideDelay(@configuration.timeBetweenSlides * 2)
        ))


    setup: (@configuration) ->
      # @logToConsole "setup: there are #{@configuration.pairs.length} image pairs. Each image is #{@configuration.imageDimensions.width} pixels wide"
      @logToConsole "setup with view factory changed name..."

      # @targetDivName = @configuration.targetDivName
      # @targetDiv = $("#" + @targetDivName)

      # define an outer/inner wrapper streucture such that we can scale the outer one to window width, but fix the inner one to an even width if desired
      outermostWrapperName = @configuration.targetDivName
      @outermostWrapperDiv = $("#" + outermostWrapperName)
      @outermostWrapperDiv.css("height", "auto")

      @targetDivName = outermostWrapperName + "_even"
      @targetDiv = $("<div/>").attr("id", @targetDivName).appendTo(@outermostWrapperDiv)

      # define a span where we can stuff the current pair data. Simplifies analyics tracking.
      @googleAnalyticsSpan = $("<span/>").css("display","none").attr("id", "barndoorCurrentPair").appendTo(@targetDiv)

      @appModel = Model.buildModelFromConfigurationObject(@configuration)
      # @appModel.debug()

      @imageLoader = new ImageLoader()

      @imageQualityManager = new ImageQualityManager(@appModel.getAllAvailableImageDimensionTypes())

      @viewFactory = new ResponsiveViewFactory(this, outermostWrapperName, @targetDivName)
      $(document).bind('viewHandlerChanged', ((evt, data) =>
        @swapInView()
      ))
      @swapInView() # initial setup

      $(document).bind('screenSizeChanged', ((evt, data) =>
        console.log("screen size changed to [" + data.width + "]x[" + data.height + "]");
        @view?.responsiveUpdate()
      ))

      # @autoplayTimeout = setTimeout((=> this.continueSlideshow()), @configuration.timeBetweenSlides)
      autoplayCookiePref = CookieUtils.readCookie(AUTOPLAY_COOKIE_NAME)

      if (autoplayCookiePref == undefined or autoplayCookiePref != "false")
        @logToConsole("no cookie or indeterminate value. Proceeding to check configuration for autoplay verdict")
        if (@configuration.autoplay != "false")
          @logToConsole("autoplay enabled...")
          @setNextSlideDelay()
        else
          @logToConsole("autoplay disabled...")
      else
        @logToConsole("cookie preference is preventing slideshow autoplay")
      @view?.updatePlayPauseStatus(not @isSlideshowPaused())

    debugWrapperWidths: () ->
      output = "OUTER WRAPPER: " + @outermostWrapperDiv.width() + " /  INNER EVEN: " + @targetDiv.width()
      $("#debugEvenWidth").html(output)

    swapInView: () ->
      if @view?
        @view.pseudoDestructor()
        @view = null

      @view = @viewFactory.constructActiveView(this, @targetDivName, @appModel.getImageDimensionAspectRatio())
      @view.supplyAllDetailText(@appModel.getDetailTextForAllSlides())

      # google analytics needs to attach to various things that we have setup; can't do that til the view is built
      $.event.trigger({ type: "ga_barndoorConstructionComplete" })

      activePair = @appModel.getActivePair()
      @imageLoader.ensureImagesLoaded(@getCorrectImageUrlsForPair(activePair), ( =>
        @view?.renderInitialView(@appModel.getActivePair())
        @googleAnalyticsSpan.html(@appModel.getActivePairAndNeighborsDescriptor())

        @preloadNextPair()
      ))

    getAssetServerUrl: () ->
      return @configuration.assetServerUrl

    getCorrectImageUrlsForPair: (pair) ->
      return pair.getAppropriateSlideImageUrls(@imageQualityManager.getImageTypeForRendering())

    getImageDimensionType: () ->
      return @imageQualityManager.getImageTypeForRendering()
      

    # loads the next set of images. No callback / fire and forget. If it hasn't finished by the time the n
    preloadNextPair: () ->
      peekPair = @appModel.getLookaheadPair()
      @imageLoader.ensureImagesLoaded(@getCorrectImageUrlsForPair(peekPair))

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

      # @logToConsole "---------------------"
      # @logToConsole "---------------------"
      # @logToConsole "---------------------"

      activePair = @appModel.getActivePair()
      @imageLoader.ensureImagesLoaded(@getCorrectImageUrlsForPair(activePair), ( =>
        @view?.showNextPair(@appModel.activePairIndex, activePair)
        @googleAnalyticsSpan.html(@appModel.getActivePairAndNeighborsDescriptor())
        @preloadNextPair()
        @setNextSlideDelay()
      ))

  return BarnDoorController
)
