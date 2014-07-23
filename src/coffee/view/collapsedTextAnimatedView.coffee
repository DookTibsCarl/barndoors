define(["view/animatedview", "view/fullTextBelowAnimatedView"], (AnimatedView, FullTextBelowAnimatedView) ->
  class CollapsedTextAnimatedView extends FullTextBelowAnimatedView
    DRAWER_CLASS = "bdDrawer"
    TITLE_CLASS = "title"
    ARROW_CLASS = "bdDrawerArrow"
    DETAILS_CLASS = "details"
    EXPANDED_TEXT_PROPORTION = .4

    constructor: (@mainController, @targetDivName, @imageAspectRatio) ->
      super(@mainController, @targetDivName, @imageAspectRatio)
      @expandedState = false
      # @expanders = [@slideContainerDiv] # if we don't expand the targetDiv too, the expanded state can overlap elements positioned right below the widget...
      @expanders = [@targetDiv, @slideContainerDiv]

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
        overflow: "hidden"
      }

      arrowStyle = {
        cursor: "pointer"
        bottom: 0
        "background-color": "grey"
        "text-align": "center"
      }

      detailsStyle = {
        letterSpacing: "1px",
        # font: "12px/12px Arial",
        color: "white"
        "background-color": "#7095B7"
        "text-align": otherSide
        top: 0
        display: "table-cell"
        "vertical-align": "middle"
      }

      titleWrapperStyle = {
        position: "absolute"
        width: "100%"
      }

      titleStyle = {
        position: "absolute"
        letterSpacing: "1px"
        color: "white"
        # font: "bold 30px/30px Helvetica, Sans-Serif"
        "text-align": otherSide
        "line-height": "90%"
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
      $("<img/>").css({height: "50%", "margin-top": "2%"}).appendTo(arrowEl)
      # $("<img/>").css({height: 12, "margin-top": "-2px"}).appendTo(arrowEl)

      arrowEl.click(( => @clickedDrawer(arrowEl)))

      imgEl = $("<img/>").attr({ id: "image" + elementSuffix }).css({ position: "absolute" }).appendTo(doorEl)

      titleWrapper = $("<div/>").attr("id", "title_wrapper" + elementSuffix).css(titleWrapperStyle).appendTo(doorEl)
      titleEl = $("<div/>").attr("id", "title" + elementSuffix).addClass(TITLE_CLASS).css(titleStyle).appendTo(titleWrapper)
      # titleEl = $("<div/>").attr("id", "title" + elementSuffix).addClass(TITLE_CLASS).css(titleStyle).appendTo(doorEl)
      # @putDoorInOpenPosition(doorEl, side)

      ###
      for hider in [titleEl, imgEl]
        hider.css("display", "none")
      ###

    clickedDrawer: (drawerEl) ->
      @expandedState = not @expandedState
      @setExpanderText()
      
      for animater in @expanders
        animater.animate({
          "height": (if @expandedState then @getExpandedSlideContainerHeight() else @getCollapsedSlideContainerHeight())
        }, {
          "easing": AnimatedView.EASE_FXN
          "duration": 100
        })

    setExpanderText: () ->
      allArrowImagess = $("." + ARROW_CLASS + " > img")

      arrowImage = if @expandedState then "up" else "down"
      arrowAlt = if @expandedState then "hide" else "show"
      allArrowImagess.attr({"src": "/global_stock/images/barndoors/barndoors-" + arrowImage + ".png", "alt": arrowAlt})

    setupCalculations: () ->
      super
      @desiredDrawerArrowHeight = @targetDiv.height() - @maxDesiredImageHeight
      # @desiredDrawerArrowHeight = 23
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

      # if (@expandedState)
        # @targetDiv.height(@dynamicImageHeight + @desiredDrawerArrowHeight + @desiredDrawerDescriptionHeight)

    # *B*
    updateDoorElementsForCurrentDimensions: (side, elementSuffix) ->
      super(side, elementSuffix)
      $("#drawer_arrow" + elementSuffix).css({height: @desiredDrawerArrowHeight, padding: @textPadAmount })
      $("#details" + elementSuffix).css({height: @desiredDrawerDescriptionHeight, "font-size": @figureScaledFontSize(AnimatedView.DESC_FONT_SCALE_DATA, @dynamicImageHeight) })
      $("#title_wrapper" + elementSuffix).css({height: @dynamicImageHeight})
      $("#title" + elementSuffix).css({bottom: 0, "font-size": @figureScaledFontSize(AnimatedView.TITLE_FONT_SCALE_DATA, @dynamicImageHeight) })

      if (@expandedState)
        for animater in @expanders
          animater.height(@getExpandedSlideContainerHeight())

      @setExpanderText()


  return CollapsedTextAnimatedView
)
