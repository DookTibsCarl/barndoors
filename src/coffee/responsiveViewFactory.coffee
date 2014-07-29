###

this class is responsible for returning a valid instance of BaseView to the controller. This depends on:
  1. screen size
  2. device capability

the main app controller just gets back an object that conforms (informally since this is JS) to some interface,
and does not care about the specifics of the implementation.

###

define(["view/diagonalAnimatedView", "view/fulltextBelowAnimatedView", "view/collapsedTextAnimatedView", "view/simpleview"],
(DiagonalAnimatedView, FullTextBelowAnimatedView, CollapsedTextAnimatedView, SimpleView) ->
  class ResponsiveViewFactory
    # specify size as a breakpoint. Anything <= a given size falls into that bucket. Final element catches everything regardless
    @BREAKPOINTS = [
      { size: 539, descriptor: "expandable" },
      { size: 799, descriptor: "fullTextBelow" }
      { descriptor: "diagonal" }
    ]
      
    constructor: (@mainController, @targetDivId) ->
      # @$ = jq

      @breakPointIndex = 0
      $(window).resize((=> @windowWasResized()))
      @windowWasResized(true)

      # got a couple of bugs involving display artifacts when running for a long time; I think related to css animations
      # acting screwy when getting stopped in the middle of a display sleep, etc. Adding a couple of methods here
      # to force redraws when things like browser tab is hidden/reshown, etc.
      @watchWindowForVisibilityStatusChanges()
      @heartbeat()

    HEARTBEAT_DELAY = 30 * 1000
    LAST_HEARTBEAT = -1
    heartbeat: () ->
      if (!Date.now)
        # shim for Date.now
        Date.now = (() ->
          return new Date().getTime()
        )

      if LAST_HEARTBEAT == -1
        LAST_HEARTBEAT = Date.now()

      nowStamp = Date.now()

      stampDiff = nowStamp - LAST_HEARTBEAT

      if (stampDiff > HEARTBEAT_DELAY * 1.5)
        console.log("[" + stampDiff + "] elapsed since last heartbeat; significantly exceeds threshold [" + HEARTBEAT_DELAY + "]; possibly waking up from sleep? screen redraw.")
        @triggerScreenSizeRefresh()

      LAST_HEARTBEAT = nowStamp
      setTimeout((=> this.heartbeat()), HEARTBEAT_DELAY)

    watchWindowForVisibilityStatusChanges: () ->
      console.log("Setting up visibility checks...")
      hidden = "hidden"

      factoryHandle = this

      onChange = ((evt) ->
        # console.log "onChange firing!"
        # console.log evt

        v = "visible"
        h = "hidden"
        evtMap = {
          focus: v
          focusin: v
          pageshow: v
          blur: h
          focusout: h
          pagehide: h
        }

        evt = evt or window.event
        smart = false
        # console.log ("event type is [" + evt.type + "]")
        if (evtMap[evt.type] != undefined)
          console.log "FALLBACK: [" + evtMap[evt.type] + "]!"
          changeType = evtMap[evt.type]
        else
          smart = true
          console.log "MODERN: " + (if (this[hidden]) then h else v)
          changeType = (if (this[hidden]) then h else v)

        # force a redraw when we become visible again
        if (changeType == v)
          console.log "explicit redraw after window becomes visible again"
          factoryHandle.triggerScreenSizeRefresh()

          if (smart and factoryHandle.restartSlideshowOnResume)
            console.log "restarting slideshow after revisible"
            $.event.trigger({ type: "toggleAutoplaySlideshow" })
            factoryHandle.restartSlideshowOnResume = false
        else
          if (smart and not factoryHandle.mainController.isSlideshowPaused())
            console.log "pausing slideshow when window hides"
            factoryHandle.triggerScreenSizeRefresh()
            factoryHandle.restartSlideshowOnResume = true
            $.event.trigger({ type: "toggleAutoplaySlideshow" })
          else 
            factoryHandle.restartSlideshowOnResume = false
      )

      if hidden of document
        # console.log("HIT A - vis")
        document.addEventListener("visibilitychange", onChange)
      else if (hidden = "mozHidden") of document
        # console.log("HIT B - moz")
        document.addEventListener("mozvisibilitychange", onChange)
      else if (hidden = "webkitHidden") of document
        # console.log("HIT C - webkit")
        document.addEventListener("webkitvisibilitychange", onChange)
      else if (hidden = "msHidden") of document
        # console.log("HIT D - ms")
        document.addEventListener("msvisibilitychange", onChange)
      else if ('onfocusin' of document)
        # console.log("HIT E - old ie")
        # IE 9 and lower
        document.onfocusin = document.onfocusout = onChange
      else
        # console.log("HIT F - backup")
        # all others
        window.onpageshow = window.onpagehide = window.onfocus = window.onblur = onChange

    findBreakpointIndex: (width) ->
      for bp, i in ResponsiveViewFactory.BREAKPOINTS
        if (bp.size? and width <= bp.size)
          return i
      
      return ResponsiveViewFactory.BREAKPOINTS.length - 1

    getActiveViewDescriptor: () ->
      return ResponsiveViewFactory.BREAKPOINTS[@breakPointIndex].descriptor

    constructActiveView: (mainAppController, divName, imgAspectRatio) ->
      console.log "BUILDING ACTIVE VIEW WITH ASPECT RATIO [" + imgAspectRatio + "]"
      desc = @getActiveViewDescriptor()
      rv = null

      if (desc == "expandable")
        # rv = new SimpleView(mainAppController, divName, imgAspectRatio)
        rv = new CollapsedTextAnimatedView(mainAppController, divName, imgAspectRatio)
      else if (desc == "fullTextBelow")
        rv = new FullTextBelowAnimatedView(mainAppController, divName, imgAspectRatio)
      else if (desc == "diagonal")
        rv = new DiagonalAnimatedView(mainAppController, divName, imgAspectRatio)

      return rv

    triggerScreenSizeRefresh: () ->
      elForDims = $("#" + @targetDivId)
      w = elForDims.width()
      h = elForDims.height()

      $(document).trigger('screenSizeChanged', {
        'width': w
        'height': h
      })
      

    windowWasResized: (forceChange = false) ->
      # w = $(window).width()
      # h = $(window).height()

      elForDims = $("#" + @targetDivId)
      w = elForDims.width()
      h = elForDims.height()
      $("#debugRVFWidth").text(w)
      $("#debugRVFHeight").text(h)

      if elForDims.length == 0
        $("#debugRVFWidth").text("NOT SET")

      oldIdx = @breakPointIndex
      updatedIdx = @findBreakpointIndex(w)
      # console.log "width=" + w + "...old=" + oldIdx + ", updated=" + updatedIdx

      if (oldIdx != updatedIdx or forceChange)
        @breakPointIndex = updatedIdx 
        $("#debugRespView").text(@getActiveViewDescriptor())
        $(document).trigger('viewHandlerChanged', { 'viewDescriptor': @getActiveViewDescriptor() })
      else
        # what are the absolute smallest and largest values for the width? need this to calculate font scaling
        # absMin = 300
        # absMax = 1147
        @triggerScreenSizeRefresh()
        

  return ResponsiveViewFactory
)
