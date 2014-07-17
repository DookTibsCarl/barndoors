define(["view/animatedview", "view/fullTextBelowAnimatedView"], (AnimatedView, FullTextBelowAnimatedView) ->
  class CollapsedTextAnimatedView extends FullTextBelowAnimatedView
    DRAWER_CLASS = "bdDrawer"
    TITLE_CLASS = "bdTitle"
    ARROW_CLASS = "bdDrawerArrow"
    DETAILS_CLASS = "bdDrawerDetails"
    EXPANDED_TEXT_PROPORTION = .25

    constructor: (@mainController, @targetDivName, @imageAspectRatio) ->
      super(@mainController, @targetDivName, @imageAspectRatio)
      @expandedState = false

    buildOutDoor: (doorEl, letter, letterLooper, side, otherSide, elementSuffix) ->
      doorStyle = {
        position: "inherit",
        display: (if letterLooper == 0 then "block" else "none")
        height: "100%"
        overflow: "hidden"
        "border-style": "solid"
        "border-width": "1px"
        "border-color": "white"
      }

      drawerStyle = {
        position: "absolute"
        letterSpacing: "1px",
        font: "12px/12px Arial",
        color: "white"
        width: "100%"
        "background-color": "orange"
        bottom: 0
      }

      arrowStyle = {
        cursor: "pointer"
        bottom: 0
        "background-color": "grey"
        "text-align": "center"
      }

      detailsStyle = {
        letterSpacing: "1px",
        font: "12px/12px Arial",
        color: "white"
        "background-color": "#7095B7"
        "text-align": otherSide
        top: 0
      }

      titleWrapperStyle = {
        position: "absolute"
        width: "100%"
      }

      titleStyle = {
        position: "absolute"
        letterSpacing: "1px"
        color: "white"
        font: "bold 30px/30px Helvetica, Sans-Serif"
        "text-align": otherSide
      }

      # use border-box to keep things reasonable
      for style in [ doorStyle, drawerStyle, detailsStyle, arrowStyle, titleStyle ]
        for sanity in [ "", "-moz-", "-webkit-" ]
          style[sanity + "box-sizing"] = "border-box"


      doorEl.css(doorStyle)

      # add the drawer first so it can slide "behind" the image/text
      drawerEl = $("<div/>").attr("id", "drawer" + elementSuffix).addClass(DRAWER_CLASS).css(drawerStyle).appendTo(doorEl)
      detailsEl = $("<div/>").attr("id", "details" + elementSuffix).addClass(DETAILS_CLASS).css(detailsStyle).appendTo(drawerEl)
      arrowEl = $("<div/>").attr("id", "drawer_arrow" + elementSuffix).addClass(ARROW_CLASS).css(arrowStyle).appendTo(drawerEl)
      arrowEl.click(( => @clickedDrawer(arrowEl)))

      imgEl = $("<img/>").attr({ id: "image" + elementSuffix }).css({ position: "absolute" }).appendTo(doorEl)
      # imgEl.css("display", "none") # hide the image to help setting up the drawer

      titleWrapper = $("<div/>").attr("id", "title_wrapper" + elementSuffix).css(titleWrapperStyle).appendTo(doorEl)
      titleEl = $("<div/>").attr("id", "title" + elementSuffix).addClass(TITLE_CLASS).css(titleStyle).appendTo(titleWrapper)
      # titleEl = $("<div/>").attr("id", "title" + elementSuffix).addClass(TITLE_CLASS).css(titleStyle).appendTo(doorEl)
      # @putDoorInOpenPosition(doorEl, side)

    clickedDrawer: (drawerEl) ->
      @expandedState = not @expandedState
      @setExpanderText()
      
      @slideContainerDiv.animate({
        "height": (if @expandedState then @getExpandedSlideContainerHeight() else @getCollapsedSlideContainerHeight())
        # "height": @dynamicImageHeight + @desiredDrawerArrowHeight + (if @expandedState then @desiredDrawerDescriptionHeight else 0)
        # "height": @slideContainerDiv.height() + (@desiredDrawerDescriptionHeight * (if @expandedState then 1 else -1))
      }, {
        "easing": AnimatedView.EASE_FXN
        "duration": 100
      })

    setExpanderText: () ->
      if (@expandedState)
        $("." + ARROW_CLASS).html("^")
      else
        $("." + ARROW_CLASS).html("v")

    setupCalculations: () ->
      super
      @desiredDrawerArrowHeight = @targetDiv.height() - @maxDesiredImageHeight
      @desiredDrawerDescriptionHeight = @maxDesiredImageHeight * EXPANDED_TEXT_PROPORTION

    getExpandedSlideContainerHeight: () ->
      return @getCollapsedSlideContainerHeight() + @desiredDrawerDescriptionHeight

    getCollapsedSlideContainerHeight: () ->
      return @dynamicImageHeight + @desiredDrawerArrowHeight


    # for a couple of things (*A*, *B*, the parent class does MOST of what we want...we can let it do its work first, and then just make some tweaks.
    # *A*
    # we want half as much of an area at the bottom on this type of view as we do on the one where text is always displayed
    enforceAspectRatio: () ->
      super
      bottomPadding = @targetDiv.height() - @maxDesiredImageHeight
      console.log "desired dims [" + @maxDesiredImageHeight + "], actual w=[" + @targetDiv.width()/2 + "],h=[" + @targetDiv.height() + "], pad amt [" + bottomPadding + "]"
      @targetDiv.height(@targetDiv.height() - bottomPadding/2)

      if (@expandedState)
        @slideContainerDiv.height(@dynamicImageHeight + @desiredDrawerArrowHeight + @desiredDrawerDescriptionHeight)

    # *B*
    updateDoorElementsForCurrentDimensions: (side, elementSuffix) ->
      super(side, elementSuffix)
      $("#drawer_arrow" + elementSuffix).css({height: @desiredDrawerArrowHeight, padding: @textPadAmount })
      $("#details" + elementSuffix).css({height: @desiredDrawerDescriptionHeight })
      $("#title_wrapper" + elementSuffix).css({height: @dynamicImageHeight})
      $("#title" + elementSuffix).css({bottom: 0})

      if (@expandedState)
        @slideContainerDiv.height(@getExpandedSlideContainerHeight())

      @setExpanderText()


  return CollapsedTextAnimatedView
)
