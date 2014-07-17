define(["view/animatedview", "view/fullTextBelowAnimatedView"], (AnimatedView, FullTextBelowAnimatedView) ->
  class CollapsedTextAnimatedView extends FullTextBelowAnimatedView
    EXPANDER_CLASS = "bdExpander"
    TITLE_CLASS = "bdTitle"
    ARROW_CLASS = "bdExpanderArrow"
    DETAILS_CLASS = "bdExpanderDetails"
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
        # height: "100%"
        # "text-align": "center"
        # "background-color": "grey"
        "background-color": "orange"
        bottom: 0
      }

      arrowStyle = {
        cursor: "pointer"
        bottom: 0
        "background-color": "pink"
      }

      detailsStyle = {
        # position: "absolute"
        letterSpacing: "1px",
        font: "12px/12px Arial",
        color: "white"
        "background-color": "#7095B7"
        # height: "100%"
        "text-align": otherSide
        top: 0
        
        "border-style": "solid"
        "border-width": "5px"
        "border-color": "green"
      }

      titleStyle = {
        position: "absolute"
        letterSpacing: "1px"
        color: "white"
        font: "bold 30px/30px Helvetica, Sans-Serif"
        "text-align": otherSide
      }

      # add the drawer first so it can slide "behind" the image/text
      drawerEl = $("<div/>").attr("id", "drawer" + elementSuffix).addClass(EXPANDER_CLASS).css(drawerStyle).appendTo(doorEl)
      detailsEl = $("<div/>").attr("id", "details" + elementSuffix).addClass(DETAILS_CLASS).css(detailsStyle).appendTo(drawerEl)
      arrowEl = $("<div/>").attr("id", "drawer_arrow" + elementSuffix).addClass(ARROW_CLASS).css(arrowStyle).appendTo(drawerEl)
      arrowEl.click(( => @clickedDrawer(arrowEl)))

      imgEl = $("<img/>").attr({ id: "image" + elementSuffix }).css({ position: "absolute" }).appendTo(doorEl)
      # imgEl.css("display", "none") # hide the image to help setting up the drawer

      # use border-box to keep things reasonable
      for style in [ doorStyle, drawerStyle, detailsStyle, titleStyle ]
        for sanity in [ "", "-moz-", "-webkit-" ]
          style[sanity + "box-sizing"] = "border-box"

      doorEl.css(doorStyle)

      titleEl = $("<div/>").attr("id", "title" + elementSuffix).addClass(TITLE_CLASS).css(titleStyle).appendTo(doorEl)
      # detailsEl = $("<div/>").attr("id", "details" + elementSuffix).css(detailsStyle).appendTo(doorEl)
      # @putDoorInOpenPosition(doorEl, side)

    clickedDrawer: (drawerEl) ->
      @expandedState = not @expandedState
      @setExpanderText()
      
      @slideContainerDiv.animate({
        # "height": @dynamicImageHeight + @desiredDrawerArrowHeight + (if @expandedState then @desiredDrawerDescriptionHeight else 0)
        "height": @slideContainerDiv.height() + (@desiredDrawerDescriptionHeight * (if @expandedState then 1 else -1))
      }, {
        "easing": AnimatedView.EASE_FXN
        "progress": ((a,p,r) => @onAnimationProgress(a,p,r))
        "duration": 100
      })

    onAnimationProgress: (anim, prog, remaining) ->
      # the title is positioned based on "bottom" - when the slide container div gets taller, this would move the title down. This corrects for that.
      updatedTitlePos = @slideContainerDiv.height() - @dynamicImageHeight
      $("." + TITLE_CLASS).css("bottom", updatedTitlePos)

    setExpanderText: () ->
      if (@expandedState)
        $("." + ARROW_CLASS).html("COLLAPSE").css("color", "purple")
      else
        $("." + ARROW_CLASS).html("EXPAND").css("color", "yellow")

    setupCalculations: () ->
      super
      @desiredDrawerArrowHeight = @targetDiv.height() - @maxDesiredImageHeight
      @desiredDrawerDescriptionHeight = @maxDesiredImageHeight * EXPANDED_TEXT_PROPORTION

    # for a couple of things (*A*, *B*, the parent class does MOST of what we want...we can let it do its work first, and then just make some tweaks.
    # *A*
    # we want half as much of an area at the bottom on this type of view as we do on the one where text is always displayed
    enforceAspectRatio: () ->
      super
      bottomPadding = @targetDiv.height() - @maxDesiredImageHeight
      console.log "desired dims [" + @maxDesiredImageHeight + "], actual w=[" + @targetDiv.width()/2 + "],h=[" + @targetDiv.height() + "], pad amt [" + bottomPadding + "]"
      @targetDiv.height(@targetDiv.height() - bottomPadding/2)

    # *B*
    updateDoorElementsForCurrentDimensions: (side, elementSuffix) ->
      super(side, elementSuffix)
      $("#drawer_arrow" + elementSuffix).css({height: @desiredDrawerArrowHeight })
      $("#details" + elementSuffix).css({height: @desiredDrawerDescriptionHeight })

      @setExpanderText()


  return CollapsedTextAnimatedView
)
