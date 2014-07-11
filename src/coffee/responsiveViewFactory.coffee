###

this class is responsible for returning a valid instance of BaseView to the controller. This depends on:
  1. screen size
  2. device capability

the main app controller just gets back an object that conforms (informally since this is JS) to some interface,
and does not care about the specifics of the implementation.

###

define(["view/defaultview", "view/simpleview"], (DefaultView, SimpleView) ->
  class ResponsiveViewFactory
    # specify size as a breakpoint. Anything <= a given size falls into that bucket. Final element catches everything regardless
    @BREAKPOINTS = [
      { size: 808, descriptor: "small" },
      { descriptor: "normal" }
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

    constructActiveView: (mainAppController, divName, imgWidth, imgHeight) ->
      desc = @getActiveViewDescriptor()
      rv = null

      if (desc == "small")
        rv = new SimpleView(mainAppController, divName, imgWidth, imgHeight)
      else if (desc == "normal")
        rv = new DefaultView(mainAppController, divName, imgWidth, imgHeight)
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
