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
      
    constructor: () ->
      # @$ = jq

      @breakPointIndex = 0
      $(window).resize((=> @windowWasResized()))
      @windowWasResized(true)

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

    windowWasResized: (forceChange = false) ->
      w = $(window).width()
      h = $(window).height()
      $("#debugWindowWidth").text(w)
      $("#debugWindowHeight").text(h)

      oldIdx = @breakPointIndex
      updatedIdx = @findBreakpointIndex(w)
      # console.log "width=" + w + "...old=" + oldIdx + ", updated=" + updatedIdx

      if (oldIdx != updatedIdx or forceChange)
        @breakPointIndex = updatedIdx 
        $("#debugRespView").text(@getActiveViewDescriptor())
        $(document).trigger('viewHandlerChanged', { 'viewDescriptor': @getActiveViewDescriptor() })
      else
        $(document).trigger('screenSizeChanged', { 'width': w, 'height': h })
        

  return ResponsiveViewFactory
)
