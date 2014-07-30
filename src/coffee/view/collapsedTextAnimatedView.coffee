define(["view/animatedview", "view/fullTextBelowAnimatedView"], (AnimatedView, FullTextBelowAnimatedView) ->
  class CollapsedTextAnimatedView extends FullTextBelowAnimatedView
    DRAWER_CLASS = "bdDrawer"
    TITLE_CLASS = "title"
    ARROW_CLASS = "bdDrawerArrow"
    DETAILS_CLASS = "details"
    EXPANDED_TEXT_PROPORTION = .6

    @DESC_FONT_SCALE_DATA = { ratio: 15, min: 14, max: 999 }

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
        # "background-color": "purple"
        "border-style": "solid"
        "border-width": "1px"
        "border-color": "white"
      }

      drawerStyle = {
        position: "absolute"
        # letterSpacing: "1px",
        font: "12px/12px Arial",
        # color: "white"
        width: "100%"
        # "background-color": "orange"
        # "background-color": "#7095B7"
        bottom: 0
        overflow: "hidden"
      }

      arrowStyle = {
        cursor: "pointer"
        position: "absolute"
        bottom: 0
        width: "100%"
        "background-color": "grey"
        "text-align": "center"
      }

      detailsStyle = {
        # letterSpacing: "1px",
        # font: "12px/12px Arial",
        # color: "white"
        # "background-color": "#7095B7"
        "text-align": otherSide
        position: "absolute"
        overflow: "hidden"
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
        # letterSpacing: "1px"
        # color: "white"
        # font: "bold 30px/30px Helvetica, Sans-Serif"
        bottom: 0
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
      # $("<img/>").css({height: "50%", "margin-top": "2%"}).appendTo(arrowEl)
      $("<img/>").css({height: 12, "margin-top": "8px"}).appendTo(arrowEl)

      arrowEl.click(( => @clickedDrawer(arrowEl)))

      imgEl = $("<img/>").attr({ id: "image" + elementSuffix }).css({ position: "absolute", "box-sizing": "border-box" }).appendTo(doorEl)

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
        ###
        if (AnimatedView.ANIMATION_TECHNIQUE == AnimatedView.USE_CSS_FOR_ANIMATION)
          @setCssHeight(animater, (if @expandedState then @getExpandedSlideContainerHeight() else @getCollapsedSlideContainerHeight()), 100)
        else if (AnimatedView.ANIMATION_TECHNIQUE == AnimatedView.USE_JQUERY_FOR_ANIMATION)
        ###

        animater.animate({
          height: @getCurrentStateSlideContainerHeight()
        }, {
          "easing": AnimatedView.JQUERY_EASE_FXN
          "duration": 100
        })

    setExpanderText: () ->
      allArrowImagess = $("." + ARROW_CLASS + " > img")

      arrowImage = if @expandedState then "up" else "down"
      arrowAlt = if @expandedState then "hide" else "show"
      allArrowImagess.attr({"src": @mainController.getAssetServerUrl() + "/global_stock/images/barndoors/barndoors-" + arrowImage + ".png", "alt": arrowAlt})

    setupCalculations: () ->
      super
      # this moved down into enforceAspectRatio - we need to know the height there.
      # @desiredDrawerArrowHeight = @targetDiv.height() - @maxDesiredImageHeight

      # this is gonna have to move elsewhere...
      # @desiredDrawerDescriptionHeight = @maxDesiredImageHeight * EXPANDED_TEXT_PROPORTION
      @desiredDrawerDescriptionHeight = 0

    getCurrentStateSlideContainerHeight: () ->
      return (if @expandedState then @getExpandedSlideContainerHeight() else @getCollapsedSlideContainerHeight())

    getExpandedSlideContainerHeight: () ->
      return @getCollapsedSlideContainerHeight() + @desiredDrawerDescriptionHeight

    getCollapsedSlideContainerHeight: () ->
      return @dynamicImageHeight + @desiredDrawerArrowHeight


    # for some things (*X*, etc the parent class does MOST of what we want...we can let it do its work first, and then just make some tweaks.
    # *A*
    # we want half as much of an area at the bottom on this type of view as we do on the one where text is always displayed
    enforceAspectRatio: () ->
      super
      @desiredDrawerArrowHeight = 25
      @targetDiv.height(@maxDesiredImageHeight + @desiredDrawerArrowHeight)

      ###
      bottomPadding = @targetDiv.height() - @maxDesiredImageHeight
      @logToConsole "desired dims [" + @maxDesiredImageHeight + "], actual w=[" + @targetDiv.width()/2 + "],h=[" + @targetDiv.height() + "], pad amt [" + bottomPadding + "]"
      @targetDiv.height(@targetDiv.height() - bottomPadding/2)
      @logToConsole("aspect restricted window to [" + @targetDiv.width() + "]x[" + @targetDiv.height() + "]")
      ###

      # if (@expandedState)
        # @targetDiv.height(@dynamicImageHeight + @desiredDrawerArrowHeight + @desiredDrawerDescriptionHeight)

    # calling super implementation was making things extremely roundabout. Copying some code for now.
    updateDoorElementsForCurrentDimensions: (side, elementSuffix) ->
      # adjust the door
      $("#door" + elementSuffix).css({ width: @halfDiv })

      imgPos = if (side == AnimatedView.SIDE_LEFT) then 0 else -1 * @foldEmount
      $("#image" + elementSuffix).width(@dynamicImageWidth).height(@dynamicImageHeight).css({left: imgPos, "max-width": @targetDiv.width()})

      $("#title_wrapper" + elementSuffix).css({height: @dynamicImageHeight})

      titleStyleUpdate = {
        padding: @textPadAmount
        width: @halfDiv
        "font-size": @figureScaledFontSize(FullTextBelowAnimatedView.TITLE_FONT_SCALE_DATA, @dynamicImageHeight)
      }
      $("#title" + elementSuffix).css(titleStyleUpdate)

      # now figure out necessary details height...
      drawerDiv = $("#drawer" + elementSuffix).css({height: @desiredDrawerArrowHeight })
      $("#drawer_arrow" + elementSuffix).css({height: @desiredDrawerArrowHeight })

      detailStyleUpdateBefore = {
        "padding-left": @textPadAmount
        "padding-right": @textPadAmount
        # top: @dynamicImageHeight
        top: 0
        width: @halfDiv
        height: 0
        "font-size": @figureScaledFontSize(FullTextBelowAnimatedView.DESC_FONT_SCALE_DATA, @dynamicImageHeight)
      }
      detailsDiv = $("#details" + elementSuffix).css(detailStyleUpdateBefore)

      @setExpanderText() # sets the arrow

      # CALCULATE THE rEQUIRED HEIGHT OF THE DETAILS TEXT - START
      if (@requiredDetailVerticalSpace == -1)
        @logToConsole("!!!!! recalculating required detail vertical space!")
        @requiredDetailVerticalSpace = @getActualDetailsTextMaxHeight()

        @requiredDetailVerticalSpace += Math.ceil(@textPadAmount * 2)

        # set this now; various calcs depend on it
        @desiredDrawerDescriptionHeight = @requiredDetailVerticalSpace
        if @expanders?
          for animater in @expanders
            heightForAnimater = @getCurrentStateSlideContainerHeight()
            animater.height(heightForAnimater)

      # now that we have the max height figured, gotta re-update a few things...
      drawerDiv.css({height: @desiredDrawerArrowHeight + @desiredDrawerDescriptionHeight})
      if @renderMode == AnimatedView.RENDER_MODE_CLIP_PATH
        detailsDiv.css({"height": @requiredDetailVerticalSpace})
      else
        detailsDiv.css({"height": @requiredDetailVerticalSpace, "padding-bottom": @textPadAmount, "padding-top": @textPadAmount})


  return CollapsedTextAnimatedView
)
