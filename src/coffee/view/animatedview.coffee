# the parent class for all views that do a close/open animation as their show.

define(["view/baseview"], (BaseView) ->
  class AnimatedView extends BaseView
    @DIAGONAL_ANGLE = 80 # how sharp of an angle, measured from the base of the div, to define the slice?

    # @TEXT_SHADOWBOX_HEIGHT = 100
    @TEXT_SHADOWBOX_PERCENT = 0.2
    @TEXT_SHADOWBOX_OPACITY = 0.5

    @CONTROL_MODE_PAGINATED = "paginatedControls"
    @CONTROL_MODE_PREV_NEXT = "prevNextControls"

    # if we add any more of these, I think we need to rethink how this rendering works. It's getting close to being out of hand.
    @RENDER_MODE_DEFAULT = "defaultMode"     # standard render mode, works for IE 9+, Safari 5+, Firefox, Chrome, etc. Uses svg's with mask
    @RENDER_MODE_CLIP_PATH = "clipPathMode"  # works for builtin Android browser. Uses svg's with clip-path. Should be almost identical to default for functionality
    @RENDER_MODE_BASIC = "basicMode"         # basic render mode - does NOT use svg's. Has most features except lacks diagonal slice. Works for IE8
    @RENDER_MODE_BROWSER_TOO_OLD = "tooOld"  # browser has been deemed too old to do much of anything.

    @EASE_FXN = "swing"
    @ANIMATION_LENGTH_MS = 900

    constructor: (@mainController, @targetDivName, @imageAspectRatio) ->
      @logToConsole "constructing default view with aspect ratio [" + @imageAspectRatio + "]..."
      @logToConsole "sides are [" + BaseView.SIDES + "]"
      @targetDiv = $("##{@targetDivName}")

      @enforceAspectRatio()
      @decideOnRenderMode()

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

    decideOnRenderMode: () ->
      # basic mode is for stuff like IE8 - skip the svg, don't do the fancy diagonal slice, etc.
      @renderMode = AnimatedView.RENDER_MODE_DEFAULT
      if (!document.createElementNS)
        @renderMode = AnimatedView.RENDER_MODE_BASIC

      nua = navigator.userAgent
      isStockAndroid = ((nua.indexOf('Mozilla/5.0') > -1 and nua.indexOf('Android ') > -1 and nua.indexOf('AppleWebKit') > -1) and !(nua.indexOf('Chrome') > -1))
      if (isStockAndroid)
        @renderMode = AnimatedView.RENDER_MODE_CLIP_PATH

      if (navigator.appName == 'Microsoft Internet Explorer')
        re  = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})")
        if (re.exec(nua) != null)
          ieVer = parseFloat( RegExp.$1 )
          if (ieVer < 8.0)
            @renderMode = AnimatedView.RENDER_MODE_BROWSER_TOO_OLD

      $("#debugUserAgent").html(nua)
      $("#debugRenderMode").html(@renderMode)

      # testing modes
      # @renderMode = AnimatedView.RENDER_MODE_BASIC
      @renderMode = AnimatedView.RENDER_MODE_CLIP_PATH

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
        prevEl = $("<span/>").css({cursor:"hand"}).attr("class", "slidePrevNextControl").html("[<-] ").appendTo(controlsEl)
        @playPauseEl = $("<span/>").css({cursor: "hand", "background-color": "grey"}).appendTo(controlsEl)
        nextEl = $("<span/>").css({cursor:"hand"}).attr("class", "slidePrevNextControl").html(" [->]").appendTo(controlsEl)

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
        
      @playPauseEl.click(() ->
        classHook.togglePlayPause()
      )

    putDoorInOpenPosition: (doorEl, side) ->
      doorEl.css("left", (if side == BaseView.SIDE_LEFT then @leftDoorOpenDestination else @rightDoorOpenDestination))

    putDoorInClosedPosition: (doorEl, side) ->
      doorEl.css("left", (if side == BaseView.SIDE_LEFT then @leftDoorClosedDestination else @rightDoorClosedDestination))



    renderInitialView: (pair) ->
      @logToConsole "rendering with [" + pair + "]..."
      @leftSlide = pair.leftSlide
      @rightSlide = pair.rightSlide

      this.positionSlides(false)

    updatePlayPauseStatus: (isPlaying) ->
      @playPauseEl.html(if isPlaying then "PAUSE" else "PLAY")

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
          doorEl.animate({
            "left": destinations[i] + "px",
          }, {
            "easing": AnimatedView.EASE_FXN
            "duration": AnimatedView.ANIMATION_LENGTH_MS
            # "progress": if i == 1 then ((a,p,r) => @onAnimationProgress(a,p,r)) else null
            "complete": (=> @onAnimationComplete())
          })
        else
          doorEl.css("left", destinations[i] + "px")

    ###
    onAnimationProgress: (anim, prog, remaining) ->
      @logToConsole "animating [" + prog + "]/[" + remaining "]"
    ###

    addMidlineDebugger: () ->
      debugEl = @addNSElement("svg", "debugger", {style: "position:absolute", width:"100%", height:"100%",baseProfile:"full",version:"1.2"}, @targetDiv[0])
      debugPoints = @targetDiv.width()/2 + " 0, " + @targetDiv.width()/2 + " " + @targetDiv.height()
      @addNSElement("polyline", "midpointer", {points:debugPoints, style: "fill:none; stroke:red; stroke-width:3"}, debugEl)


    onAnimationComplete: ->
      @doorsThatFinishedAnimating++
      if @doorsThatFinishedAnimating == 2
        @currentlyAnimating = false
        # @logToConsole "ALL DOORS FINISHED!"
      else
        # @logToConsole "NOT DONE YET!"

    stopAllDoorAnimations: () ->
      for doorStorage in [@leftDoors, @rightDoors]
        for door in doorStorage
          door.finish()
      @currentlyAnimating = false


    responsiveUpdate: (w, h) ->
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
