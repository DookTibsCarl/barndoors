# the parent class for all views that do a close/open animation as their show.

# TODO - TRY MODERNIZR IN REQUIRE.JS
# TODO - SMART TEXT HEIGHTS
# TODO - fixed height drawer

define(["view/baseview"], (BaseView) ->
  class AnimatedView extends BaseView
    @DIAGONAL_ANGLE = 84.77 # how sharp of an angle, measured from the base of the div, to define the slice?

    # @TEXT_SHADOWBOX_HEIGHT = 100
    @TEXT_SHADOWBOX_PERCENT = 0.16
    @TEXT_SHADOWBOX_OPACITY = 0.5

    @USE_JQUERY_FOR_ANIMATION = "useJquery"
    @USE_CSS_FOR_ANIMATION = "useCss"
    @ANIMATION_TECHNIQUE = AnimatedView.USE_CSS_FOR_ANIMATION
    # @ANIMATION_TECHNIQUE = AnimatedView.USE_JQUERY_FOR_ANIMATION

    @CONTROL_MODE_PAGINATED = "paginatedControls"
    @CONTROL_MODE_PREV_NEXT = "prevNextControls"

    # if we add any more of these, I think we need to rethink how this rendering works. It's getting close to being out of hand.
    @RENDER_MODE_DEFAULT = "defaultMode"     # standard render mode, works for IE 9+, Safari 5+, Firefox, Chrome, etc. Uses svg's with mask
    @RENDER_MODE_CLIP_PATH = "clipPathMode"  # works for builtin Android browser. Uses svg's with clip-path. Should be almost identical to default for functionality
    @RENDER_MODE_BASIC = "basicMode"         # basic render mode - does NOT use svg's. Has most features except lacks diagonal slice. Works for IE8
    @RENDER_MODE_BROWSER_TOO_OLD = "tooOld"  # browser has been deemed too old to do much of anything.

    @JQUERY_EASE_FXN = "swing"
    @CSS_EASE_FXN = "ease-in-out" # default / linear / ease-in / ease-out / ease-in-out
    @ANIMATION_LENGTH_MS = 700

    CSS_ANIMATION_PREFIXES = ["-webkit-", "-moz-", "-o-", "-ms-", ""]

    constructor: (@mainController, @targetDivName, @imageAspectRatio) ->
      @logToConsole "constructing default view with aspect ratio [" + @imageAspectRatio + "]..."
      @logToConsole "sides are [" + BaseView.SIDES + "]"
      @targetDiv = $("##{@targetDivName}")

      @resizeDoorDestinations = []

      @browserData = @getUserAgentData()

      @decideOnRenderMode()
      @decideOnAnimationMode()

      @leftDoors = []
      @rightDoors = []

      @slideContainerDiv = $("<div/>").css({
        "width":@targetDiv.width(),
        "height":@targetDiv.height(),
        "overflow":"hidden",
        "position":"absolute"}).attr("id", "slideContainer").appendTo(@targetDiv)
      @controlContainerDiv = $("<div/>").css({"position": "absolute", "width":@targetDiv.width()}).attr("id", "controlContainer").appendTo(@targetDiv)

      @setupCalculations()

      # @slideContainerDiv.css({ "background-color": "orange", "overflow": "hidden", "position": "absolute" })

      # TODO? - stop giving things unique id's and select them based on class/hierarchy perhaps? Or if not, at least break "door"/"title"/etc. out into consts

      # Some modes require some initial setup
      if (@renderMode == AnimatedView.RENDER_MODE_BROWSER_TOO_OLD)
        @slideContainerDiv.remove()
        # @slideContainerDiv.html("sorry, browser too old")
        @controlContainerDiv.remove()
        
      @buildOutDoors()
      # @addMidlineDebugger()

      @addControls(AnimatedView.CONTROL_MODE_PREV_NEXT)

      @activeDoorIndex = 0
      @inactiveDoorIndex = 1

    wrapUpPoly: (p) ->
      p.push(p[0])

    decideOnAnimationMode: () ->
      # our default is CSS animation, but various older browsers can't handle it. Use Jquery as a backup
      if (@renderMode == AnimatedView.RENDER_MODE_BASIC)
        AnimatedView.ANIMATION_TECHNIQUE = AnimatedView.USE_JQUERY_FOR_ANIMATION

      if (@renderMode == AnimatedView.RENDER_MODE_CLIP_PATH)
        AnimatedView.ANIMATION_TECHNIQUE = AnimatedView.USE_JQUERY_FOR_ANIMATION

      # ie9 and below don't support css animation
      if (@browserData.name == "IE" and @browserData.version <= 9.0)
        AnimatedView.ANIMATION_TECHNIQUE = AnimatedView.USE_JQUERY_FOR_ANIMATION

      # older ios (iPad 1 for instance, 5.1 Safari) don't render css anim correctly.
      if (@browserData.isLikelyMobile and @browserData.name == "Safari" && @browserData.version <= 6.0)
        AnimatedView.ANIMATION_TECHNIQUE = AnimatedView.USE_JQUERY_FOR_ANIMATION

      console.log("decided on animation mode [" + AnimatedView.ANIMATION_TECHNIQUE + "]")
      $("#debugAnimationMode").html(AnimatedView.ANIMATION_TECHNIQUE)

      if (AnimatedView.ANIMATION_TECHNIQUE == AnimatedView.USE_CSS_FOR_ANIMATION)
        # -webkit-transform for isntance will enable 3d acceleration on the ios (and fixes some z-ordering bug)
        ###
        for prefix in CSS_ANIMATION_PREFIXES
          @targetDiv.css(prefix + "transform", "translateZ(0)")
        ###
        @targetDiv.css("-webkit-transform", "translateZ(0)")

    decideOnRenderMode: () ->
      # basic mode is for stuff like IE8 - skip the svg, don't do the fancy diagonal slice, etc.
      @renderMode = AnimatedView.RENDER_MODE_DEFAULT
      if (!document.createElementNS)
        @renderMode = AnimatedView.RENDER_MODE_BASIC

      if (@browserData.isStockAndroid)
        @renderMode = AnimatedView.RENDER_MODE_CLIP_PATH

      if (@browserData.name == "IE" and @browserData.version < 8.0)
        @renderMode = AnimatedView.RENDER_MODE_BROWSER_TOO_OLD

      # testing modes
      # @renderMode = AnimatedView.RENDER_MODE_BASIC
      # @renderMode = AnimatedView.RENDER_MODE_CLIP_PATH

      console.log("decided on rendering mode: [" + @renderMode + "]")
      $("#debugRenderMode").html(@renderMode)


    # handles setting up container elements for left/right, setting up suffixes, etc. actual building of the DOM is left to subclasses
    buildOutDoors: () ->
      # and now let's set up the individual A/B slides - this lets us keep one onscreen and use another for animating, and we just swap the content in each as needed.

      for side in BaseView.SIDES
        @updateSideElementsForCurrentDimensions(side)

      for letter, i in ["A","B"]
        for side in BaseView.SIDES
          elementSuffix = "_#{side}_#{i}"
          otherSide = if side == BaseView.SIDE_LEFT then "right" else "left"

          # add the necessary structure to the DOM
          doorEl = $("<div/>").attr("id", "door" + elementSuffix).appendTo(@slideContainerDiv)
          @buildOutDoor(doorEl, letter, i, side, otherSide, elementSuffix)

          ###
          if i == 1
            doorEl.css("top", 100)
          ###

          # and finally let's save things
          if (side == AnimatedView.SIDE_LEFT)
            @leftDoors.push(doorEl)
          else
            @rightDoors.push(doorEl)

          # finally - some of the elements we created via buildOutDoor may need to be fleshed out with actual x/y/w/h values, polygons for rendering/masking, etc.
          @updateDoorElementsForCurrentDimensions(side, elementSuffix)

    # during a responsive update, we need to go through the door structure and redo various positions and polygon assignments
    resizeDoors: () ->
      for side in BaseView.SIDES
        @updateSideElementsForCurrentDimensions(side)

      for letter, i in ["A","B"]
        for side in BaseView.SIDES
          elementSuffix = "_#{side}_#{i}"
          @updateDoorElementsForCurrentDimensions(side, elementSuffix)

          # reposition the door based on all of the above updates
          doorEl = $("#door" + elementSuffix)
          @putDoorInClosedPosition(doorEl, side)


    addControls: (controlType) ->
      controlsEl = $("<div/>").css({
                                    "position": "relative"
                                    "float": "right"
                                    "margin-top": "1%"
                                    "margin-right": "1%"
                                    # this top position puts controls just below the slide container
                                    # "top":@slideContainerDiv.height()
                                  }).attr("id", "barndoorControls").appendTo(@controlContainerDiv)


      classHook = this
      if (controlType == AnimatedView.CONTROL_MODE_PAGINATED)
        pairCount = @mainController.appModel.getPairCount()
        for i in [0..pairCount-1]
          jumpEl = $("<span/>").attr("class", "slideJumpControl").appendTo(controlsEl)

          jumpElStyle = {
            "background-color": "red"
            cursor: "hand"
            margin: 20
          }

          jumpEl.click(() ->
            if classHook.currentlyAnimating
            else
              classHook.jumpToIndex($(this).index())
          )

          jumpEl.css(jumpElStyle)
          jumpEl.html("slide_" + (i+1))

        @playPauseEl = $("<span/>").css({cursor: "hand", "background-color": "grey"}).appendTo(controlsEl)
        @reRenderJumpControls(@mainController.appModel.activePairIndex)
      else if (controlType == AnimatedView.CONTROL_MODE_PREV_NEXT)
        imgStyle = {
          "margin-left": "auto"
          "margin-right": "auto"
          display: "block"
          height: "60%"
          "margin-top": "18%"
        }

        prevEl = $("<a/>").addClass("round_button").addClass("previous").appendTo(controlsEl)
        # $("<img/>").attr({"src": "/global_stock/images/barndoors/barndoors-previous.png", "alt": "previous"}).css(imgStyle).appendTo(prevEl)
        $("<img/>").attr({"src": @mainController.getAssetServerUrl() + "/global_stock/images/barndoors/barndoors-previous.png", "alt": "previous"}).appendTo(prevEl)

        @playPauseElWrapper = $("<a/>").addClass("round_button").addClass("playpause").appendTo(controlsEl)
        # @playPauseEl = $("<img/>").css(imgStyle).appendTo(@playPauseElWrapper)
        @playPauseEl = $("<img/>").appendTo(@playPauseElWrapper)
        @updatePlayPauseStatus(not @mainController.isSlideshowPaused())

        nextEl = $("<a/>").addClass("round_button").addClass("next").appendTo(controlsEl)
        # $("<img/>").attr({"src": "/global_stock/images/barndoors/barndoors-next.png", "alt": "next"}).css(imgStyle).appendTo(nextEl)
        $("<img/>").attr({"src": @mainController.getAssetServerUrl() + "/global_stock/images/barndoors/barndoors-next.png", "alt": "next"}).appendTo(nextEl)
        
        for el, i in [prevEl, nextEl]
          el.click(() ->
            if ! classHook.currentlyAnimating
              if ($(this).index() == 0)
                classHook.moveToPrevIndex()
              else
                classHook.moveToNextIndex()
          )
      else
        @logToConsole("unsupported control type [" + controlType + "] supplied...")
        
      @playPauseElWrapper.click(() ->
        classHook.togglePlayPause()
      )

    putDoorInOpenPosition: (doorEl, side) ->
      doorEl.css("left", (if side == BaseView.SIDE_LEFT then @leftDoorOpenDestination else @rightDoorOpenDestination))

    putDoorInClosedPosition: (doorEl, side) ->
      doorEl.css("left", (if side == BaseView.SIDE_LEFT then @leftDoorClosedDestination else @rightDoorClosedDestination))

    renderInitialView: (pair) ->
      @logToConsole "initial render with [" + pair + "]..."
      @responsiveUpdate() # initial dimension-aware setup...
      @leftSlide = pair.leftSlide
      @rightSlide = pair.rightSlide

      this.positionSlides(false)

    updatePlayPauseStatus: (isPlaying) ->
      # @playPauseElWrapper.removeClass("isPlaying isPaused")
      if (isPlaying)
        @playPauseEl.attr({"src": @mainController.getAssetServerUrl() + "/global_stock/images/barndoors/barndoors-pause.png", "alt": "pause"})
        # @playPauseElWrapper.addClass("isPlaying")
      else
        @playPauseEl.attr({"src": @mainController.getAssetServerUrl() + "/global_stock/images/barndoors/barndoors-play.png", "alt": "play"})
        # @playPauseElWrapper.addClass("isPaused")

    reRenderJumpControls: (index) ->
      @logToConsole "update jumpers [" + index + "]"
      # spans = $("#barndoorControls > span")
      spans = $("#barndoorControls > span.slideJumpControl")
      @logToConsole spans
      for i in [0..spans.length-1]
        span = spans.eq(i)
        span.css("background-color", if i == index then "green" else "red")

      @updatePlayPauseStatus(not @mainController.isSlideshowPaused())

    showNextPair: (index, pair, reversing = false) ->
      @reRenderJumpControls(index)
      @inactiveDoorIndex = @activeDoorIndex

      @activeDoorIndex++
      if (@activeDoorIndex >= @leftDoors.length)
        @activeDoorIndex = 0

      @leftSlide = pair.leftSlide
      @rightSlide = pair.rightSlide

      oldDoors = [@leftDoors[@inactiveDoorIndex], @rightDoors[@inactiveDoorIndex]]

      if reversing
        # put the new slides behind the current ones, in the middle, and "open" the barn doors
        for doorEl, i in [@leftDoors[@activeDoorIndex], @rightDoors[@activeDoorIndex]]
          doorEl.css("display", "block")
          @stackElements(oldDoors[i], doorEl)
          @putDoorInClosedPosition(doorEl, BaseView.SIDES[i])
        @positionSlides(true, false)
      else
        # put the new slides on top of the current ones and offscreen, and "close" the barn doors
        for doorEl, i in [@leftDoors[@activeDoorIndex], @rightDoors[@activeDoorIndex]]
          doorEl.css("display", "block")
          @putDoorInOpenPosition(doorEl, BaseView.SIDES[i])
          @stackElements(doorEl, oldDoors[i])
        @positionSlides()

      @stackElements(@controlContainerDiv, @slideContainerDiv)

    positionSlides: (doAnimate = true, closeSlides = true) ->
      slides = [ @leftSlide, @rightSlide ]
      destinations = if closeSlides then [ @leftDoorClosedDestination, @rightDoorClosedDestination ] else [ @leftDoorOpenDestination, @rightDoorOpenDestination ]

      animaters = if closeSlides then [ @leftDoors[@activeDoorIndex], @rightDoors[@activeDoorIndex] ] else [ @leftDoors[@inactiveDoorIndex], @rightDoors[@inactiveDoorIndex] ]

      @currentlyAnimating = doAnimate
      @doorsThatFinishedAnimating = 0

      for doorEl, i in animaters
        suffix = "_" + BaseView.SIDES[i] + "_" + @activeDoorIndex
        slide = slides[i]

        titleEl = $("#title" + suffix)
        detailsEl = $("#details" + suffix)

        imgDomEl = document.getElementById("image" + suffix)

        if (imgDomEl == null) then continue #only happens during testing...

        imageUrl = slide.getImageUrl(@mainController.getImageDimensionType())

        if (@renderMode == AnimatedView.RENDER_MODE_BASIC or not this.enableSvgImageSwaps)
          imgDomEl.setAttribute('src', imageUrl)
        else if (@renderMode == AnimatedView.RENDER_MODE_DEFAULT or @renderMode == AnimatedView.RENDER_MODE_CLIP_PATH)
          imgDomEl.setAttributeNS(BaseView.XLINK_NS, 'href', imageUrl)
          imgDomEl.setAttribute('width', "100%")
          imgDomEl.setAttribute('height', "100%")

        # TODO? - sanitize this input? maybe allow a couple of tags but not full blown control...
        titleEl.html(slide.title)
        detailsEl.html(slide.details)

        if doAnimate
          if AnimatedView.ANIMATION_TECHNIQUE == AnimatedView.USE_CSS_FOR_ANIMATION
            distance = destinations[i] - doorEl.position().left

            # remember this for later - we need it if user resizes during the animation
            @resizeDoorDestinations[i] = destinations[i]

            # @visDebug("Animating [" + doorEl.attr('id') + "]")
            @setCssTranslationPropsForElement(doorEl, distance, 0, AnimatedView.ANIMATION_LENGTH_MS)
          else if AnimatedView.ANIMATION_TECHNIQUE == AnimatedView.USE_JQUERY_FOR_ANIMATION
            doorEl.animate({
              "left": destinations[i] + "px",
            }, {
              # "easing": AnimatedView.JQUERY_EASE_FXN
              "duration": AnimatedView.ANIMATION_LENGTH_MS
              # "progress": if i == 1 then ((a,p,r) => @onAnimationProgress(a,p,r)) else null
              "complete": (=> @onJqueryAnimationComplete())
            })
        else
          doorEl.css("left", destinations[i] + "px")

      if doAnimate and AnimatedView.ANIMATION_TECHNIQUE == AnimatedView.USE_CSS_FOR_ANIMATION
        doorEl.one('transitionend webkitTransitionEnd oTransitionEnd otransitionend MSTransitionEnd', ( => @onCssAnimationComplete()))
        # setTimeout(( => @onCssAnimationComplete()), AnimatedView.ANIMATION_LENGTH_MS + 10) # the +10 makes sure the animation has *really* completed before we call onCssAnimationComplete

    ###
    onAnimationProgress: (anim, prog, remaining) ->
      @logToConsole "animating [" + prog + "]/[" + remaining "]"
    ###

    addMidlineDebugger: () ->
      debugEl = @addNSElement("svg", "debugger", {style: "position:absolute", width:"100%", height:"100%",baseProfile:"full",version:"1.2"}, @targetDiv[0])
      debugPoints = @targetDiv.width()/2 + " 0, " + @targetDiv.width()/2 + " " + @targetDiv.height()
      @addNSElement("polyline", "midpointer", {points:debugPoints, style: "fill:none; stroke:red; stroke-width:3"}, debugEl)
    
    visDebug: (s) ->
      debugConsole = $("#debugConsole")
      debugConsole.html(s + "<BR>" + debugConsole.html())

    clearCssAnimationPropsFromAllDoors: ->
      # @visDebug("CLEARING OUT!")
      for letter, i in ["A","B"]
        for side in BaseView.SIDES
          elementSuffix = "_#{side}_#{i}"
          doorEl = $("#door" + elementSuffix)
          @clearCssAnimationPropsFromElement(doorEl)

    setCssTranslationPropsForElement: (el, xShift, yShift, duration) ->
      animationDuration = duration / 1000
      console.log("actually animating [" + el.attr('id') + "] from [" + el.position().left + "] to [" + xShift + "]...")
      for prefix in CSS_ANIMATION_PREFIXES
        el.css(prefix + "transition", animationDuration + "s " + AnimatedView.CSS_EASE_FXN)
        el.css(prefix + "transform", "translate(" + xShift + "px, " + yShift + "px)")

    ###
    # attempting to implement css animation for the expansion/collapse of the phone view
    setCssHeight: (el, height, duration) ->
      animationDuration = duration / 1000
      for prefix in CSS_ANIMATION_PREFIXES
        el.css("max-height", height)
        el.css(prefix + "transition", "max-height " + animationDuration + "s")
    ###

    clearCssAnimationPropsFromElement: (el) ->
      el.css("left", el.position().left)
      for prefix in CSS_ANIMATION_PREFIXES
        el.css(prefix + "transition", "")
        el.css(prefix + "transform", "")


    onCssAnimationComplete: ->
      if @currentlyAnimating
        console.log("CSS animation completed...")
        @clearCssAnimationPropsFromAllDoors()
        @currentlyAnimating = false

    onJqueryAnimationComplete: ->
      @doorsThatFinishedAnimating++
      if @doorsThatFinishedAnimating == 2
        @currentlyAnimating = false
        # @logToConsole "ALL DOORS FINISHED!"
      else
        # @logToConsole "NOT DONE YET!"

    stopAllDoorAnimations: () ->
      for doorStorage, i in [@leftDoors, @rightDoors]
        for door in doorStorage
          if AnimatedView.ANIMATION_TECHNIQUE == AnimatedView.USE_JQUERY_FOR_ANIMATION
            door.finish()
          else if AnimatedView.ANIMATION_TECHNIQUE == AnimatedView.USE_CSS_FOR_ANIMATION
            @clearCssAnimationPropsFromElement(door)

            if (@resizeDoorDestinations.length > 0)
              door.css("left", @resizeDoorDestinations[i])
    
      @currentlyAnimating = false


    responsiveUpdate: () ->
      @stopAllDoorAnimations()
      @enforceAspectRatio()
      @slideContainerDiv.width(@targetDiv.width()).height(@targetDiv.height())
      # @controlContainerDiv.width(@targetDiv.width()).height(@targetDiv.height())
      @controlContainerDiv.width(@targetDiv.width())

      @setupCalculations()
      @resizeDoors()

    # START - THESE SHOULD BE IMPLEMENTED IN SUBCLASSES
    enforceAspectRatio: () ->
      @logToConsole("no implementation for enforceAspectRatio")

    buildOutDoor: (letter, i, side, otherSide, elementSuffix) ->
      @logToConsole("no implementation for buildOutDoor")

    updateSideElementsForCurrentDimensions: (side) ->
      @logToConsole("no implementation for updateSideElementsForCurrentDimensions")

    updateDoorElementsForCurrentDimensions: (side, elementSuffix) ->
      @logToConsole("no implementation for updateDoorElementsForCurrentDimensions")

    setupCalculations: () ->
      @logToConsole("no implementation for setupCalculations")
    # END - THESE SHOULD BE IMPLEMENTED IN SUBCLASSES


    pseudoDestructor: ->
      @logToConsole "cleaning up custom default..."
      $("##{@targetDivName} > div").remove()
      # @targetDiv.css({ "background-color": "", "overflow": "", "position": "" })
      super

  return AnimatedView
)
