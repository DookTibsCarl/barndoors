# different views can do things like slice and dice the image, handle animating, etc.
# right now this is doing an awful lot...
define(["view/baseview"], (BaseView) ->
  class DefaultView extends BaseView
    # currently hardcoded, and polygons are associated with the overall view
    # and not with individual items. If we allow different polys per pair, 
    # need to rethink this...
    @TOP_EDGE_INSET = 40
    @BOTTOM_EDGE_INSET = 90
    @TEXT_SHADOWBOX_HEIGHT = 100
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

    constructor: (@mainController, @targetDivName, @imgWidth, @imgHeight) ->
      @logToConsole "constructing default view with img size [" + @imgWidth + "]x[" + @imgHeight + "]..."
      @logToConsole "sides are [" + BaseView.SIDES + "]"
      @targetDiv = $("##{@targetDivName}")

      @enforceAspectRatio()

      # basic mode is for stuff like IE8 - skip the svg, don't do the fancy diagonal slice, etc.
      @renderMode = DefaultView.RENDER_MODE_DEFAULT
      if (!document.createElementNS)
        @renderMode = DefaultView.RENDER_MODE_BASIC

      nua = navigator.userAgent
      isStockAndroid = ((nua.indexOf('Mozilla/5.0') > -1 and nua.indexOf('Android ') > -1 and nua.indexOf('AppleWebKit') > -1) and !(nua.indexOf('Chrome') > -1))
      if (isStockAndroid)
        @renderMode = DefaultView.RENDER_MODE_CLIP_PATH

      if (navigator.appName == 'Microsoft Internet Explorer')
        re  = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})")
        if (re.exec(nua) != null)
          ieVer = parseFloat( RegExp.$1 )
          if (ieVer < 8.0)
            @renderMode = DefaultView.RENDER_MODE_BROWSER_TOO_OLD

      # console.log "HARDCODED TESTING MODE"
      # @renderMode = DefaultView.RENDER_MODE_CLIP_PATH

      $("#debugUserAgent").html(nua)
      $("#debugRenderMode").html(@renderMode)

      @slideContainerDiv = $("<div/>").css({"width":@targetDiv.width(), "height":@targetDiv.height()}).attr("id", "slideContainer").appendTo(@targetDiv)
      @controlContainerDiv = $("<div/>").css({"position": "absolute", "width":@targetDiv.width()}).attr("id", "controlContainer").appendTo(@targetDiv)

      # do some math setup
      @precalcImageAdjustments()
      @createClippingPolygons()
      @calculateSlideDestinations()

      @slideContainerDiv.css({ "background-color": "orange", "overflow": "hidden", "position": "absolute" })

      @leftDoors = []
      @rightDoors = []

      # TODO - stop giving things unique id's and select them based on class/hierarchy perhaps? Or if not, at least break "door"/"title"/etc. out into consts

      # Some modes require some initial setup
      if (@renderMode == DefaultView.RENDER_MODE_BROWSER_TOO_OLD)
        @slideContainerDiv.remove()
        # @slideContainerDiv.html("sorry, browser too old")
        @controlContainerDiv.remove()
        
      else if (@renderMode == DefaultView.RENDER_MODE_CLIP_PATH)
        for side, i in BaseView.SIDES
          polyPoints = @translatePointsFromArrayToSVGNotation(if side == BaseView.SIDE_LEFT then @leftImagePoly else @rightImagePoly)
          svgEl = @addNSElement("svg", "", {width:0, height:0}, @slideContainerDiv[0])
          defsEl = @addNSElement("defs", "", null, svgEl)
          clipPathEl = @addNSElement("clipPath", side + "_clip_path", null, defsEl)
          polygonEl = @addNSElement("polygon", "", {points:polyPoints}, clipPathEl)

      @buildOutDoors()

      # @addControls(DefaultView.CONTROL_MODE_PAGINATED)
      @addControls(DefaultView.CONTROL_MODE_PREV_NEXT)

      @activeDoorIndex = 0

    # during a responsive update, we need to go through the door structure and get everything correctly sized again. fun.
    resizeDoors: () ->
      vertPos = (@slideContainerDiv.height()/2) - (@imgHeight/2)

      for letter, i in ["A","B"]
        for side in BaseView.SIDES
          elementSuffix = "_#{side}_#{i}"

          doorEl = $("#door" + elementSuffix)
          doorEl.css("top", vertPos + "px")

          polyPoints = @translatePointsFromArrayToSVGNotation(if side == BaseView.SIDE_LEFT then @leftImagePoly else @rightImagePoly)
          bbPoints = @translatePointsFromArrayToSVGNotation(if side == BaseView.SIDE_LEFT then @leftTextPoly else @rightTextPoly)

          @updateNSElement("maskpoly" + elementSuffix, {points:polyPoints})
          @updateNSElement("blackbox" + elementSuffix, {points:bbPoints})
          @updateNSElement("outliner" + elementSuffix, {points:polyPoints})

    buildOutDoors: () ->
      vertPos = (@slideContainerDiv.height()/2) - (@imgHeight/2)

      # and now let's set up the individual A/B slides - this lets us keep one onscreen and use another for animating, and we just swap the content in each as needed.
      for letter, i in ["A","B"]
        for side in BaseView.SIDES
          elementSuffix = "_#{side}_#{i}"
          @logToConsole "looping for [" + elementSuffix + "]"
          # add the necessary structure to the DOM
          doorEl = $("<div/>").attr("id", "door" + elementSuffix).appendTo(@slideContainerDiv)

          polyPoints = @translatePointsFromArrayToSVGNotation(if side == BaseView.SIDE_LEFT then @leftImagePoly else @rightImagePoly)

          if side == BaseView.SIDE_LEFT
            wordsX = @cutoffImageAmount - @maxInset + (@slantAdjustment * 2)
          else
            wordsX = @maxInset

          wordsWidth = @halfDiv - (@slantAdjustment * 2)

          if (@renderMode == DefaultView.RENDER_MODE_BASIC)
            imgEl = document.createElement("img")
            imgEl.id = "image" + elementSuffix
            doorEl[0].appendChild(imgEl)

            bbEl = document.createElement("div")
            bbEl.className = "blackbar_basic" # this needs to be predefined for everything to work nicely...ugly

            doorEl[0].appendChild(bbEl)
          else if (@renderMode == DefaultView.RENDER_MODE_DEFAULT or @renderMode == DefaultView.RENDER_MODE_CLIP_PATH)
            # now build out the svg stuff...this does NOT play nicely with JQuery so we just use plain JavaScript (with a helper fxn) to construct it all
            # top level - svg
            svgEl = @addNSElement("svg", "mover" + elementSuffix, {width:@imgWidth, height:@imgHeight,baseProfile:"full",version:"1.2"}, doorEl[0])

            if (@renderMode == DefaultView.RENDER_MODE_DEFAULT)
              svgImageAttribs = { mask: "url(#svgmask" + elementSuffix + ")" }

              # svgEl contains a "defs" element...
              defsEl = @addNSElement("defs", "", null, svgEl)

              # defs contains a mask...
              maskEl = @addNSElement("mask", "svgmask" + elementSuffix, {maskUnits:"userSpaceOnUse",maskContentUnits:"userSpaceOnUse",transform:"scale(1)"}, defsEl)

              # and mask contain a polygon
              console.log("poly points [" + polyPoints + "]")
              polygonEl = @addNSElement("polygon", "maskpoly" + elementSuffix, {points:polyPoints, fill:"white"}, maskEl)

            else if (@renderMode == DefaultView.RENDER_MODE_CLIP_PATH)
              svgImageAttribs = { "clip-path": "url(#" + side + "_clip_path)" }

            imgEl = @addNSElement("image", "image" + elementSuffix, svgImageAttribs, svgEl)

            # black box el is next
            bbPoints = @translatePointsFromArrayToSVGNotation(if side == BaseView.SIDE_LEFT then @leftTextPoly else @rightTextPoly)
            bbEl = @addNSElement("polygon", "blackbox" + elementSuffix, {points:bbPoints, fill:"black", "fill-opacity": DefaultView.TEXT_SHADOWBOX_OPACITY}, svgEl)

            # and now the border that appears around the edge of the slide
            @addNSElement("polyline", "outliner" + elementSuffix, {points:polyPoints, style: "fill:none; stroke:white; stroke-width:3"}, svgEl)
            # end of normal styling. CoffeeScript's lack of brackets is a little annoying sometimes

          this.putDoorInOpenPosition(doorEl, side)

          titleEl = $("<div/>").attr("id", "title" + elementSuffix).appendTo(doorEl)
          detailsEl = $("<div/>").attr("id", "details" + elementSuffix).appendTo(doorEl)

          # style things appropriately

          wordsAlignment = if side == BaseView.SIDE_LEFT then "right" else "left"
          titleStyle = {
            position: "absolute"
            bottom: DefaultView.TEXT_SHADOWBOX_HEIGHT
            left: wordsX
            width: wordsWidth
            letterSpacing: "1px"
            color: "white"
            font: "bold 30px/30px Helvetica, Sans-Serif"
            "text-align": wordsAlignment
          }

          detailsStyle = {
            # "background-color": "orange"
            position: "absolute"
            top: @imgHeight - DefaultView.TEXT_SHADOWBOX_HEIGHT
            left: wordsX
            width: wordsWidth
            letterSpacing: "1px",
            font: "12px/12px Arial",
            color: "white"
            "text-align": wordsAlignment
          }

          doorStyle = {
            position: "inherit",
            top: vertPos + "px",
            display: (if i == 0 then "block" else "none")
          }
          doorEl.css(doorStyle)
          titleEl.css(titleStyle)
          detailsEl.css(detailsStyle)


          # and finally let's save things
          if (side == BaseView.SIDE_LEFT)
            @leftDoors.push(doorEl)
          else
            @rightDoors.push(doorEl)

          @logToConsole "end of this bit"
          

    addControls: (controlType) ->
      controlsEl = $("<div/>").css({
                                    "position": "relative"
                                    "float": "right"
                                    # this top position puts controls just below the slide container
                                    # "top":@slideContainerDiv.height()
                                  }).attr("id", "barndoorControls").appendTo(@controlContainerDiv)


      classHook = this
      if (controlType == DefaultView.CONTROL_MODE_PAGINATED)
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
      else if (controlType == DefaultView.CONTROL_MODE_PREV_NEXT)
        prevEl = $("<span/>").attr("class", "slidePrevNextControl").html("[<-] ").appendTo(controlsEl)
        @playPauseEl = $("<span/>").css({cursor: "hand", "background-color": "grey"}).appendTo(controlsEl)
        nextEl = $("<span/>").attr("class", "slidePrevNextControl").html(" [->]").appendTo(controlsEl)

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

    precalcImageAdjustments: () ->
      # a couple of dimensions/calculations are used in a number of places - let's just do them up front.

      ###
      An image might make things a little clearer down the line:

      +--+
      |  |   this box represents the visible targetDiv. A vertical line shows the midpoint. A diagonal line shows
      +--+        one possible orientation of the sliced angle between the slides

      ====
      =  =   this box represents one of the two slides in its "closed" / visible position.
      ====
      
      Couple of notes:
      * the diagonal slice doesn't necessarily start at the "corner" of the image.
      * the image itself may extend beyond the visible border of the targetDiv (targetDiv has overflow==none so it will be hidden)

      Put it all together and this is more or less what things look like, showing JUST the left slide as this is confusing enough.

            +----------------------------+
      ======|=============|===/===       |
      =     |             |  /   =       |
      =     |             | /    =       |
      =     |             |/     =       |
      =     |             /      =       |
      =     |            /|      =       |
      =     |           / |      =       |
      ======|==========/==|=======       |
            +----------------------------+
                          <~~~ halfDiv ~~>

      <~~~~~~~ imgWidth ~~~~~~~~~>
      ###

      @halfDiv = @targetDiv.width()/2
      @cutoffImageAmount = @imgWidth - @halfDiv
      @slantAdjustment = Math.abs(DefaultView.TOP_EDGE_INSET - DefaultView.BOTTOM_EDGE_INSET) / 2
      @choppedPixels = Math.min(DefaultView.TOP_EDGE_INSET, DefaultView.BOTTOM_EDGE_INSET)
      @maxInset = Math.max(DefaultView.TOP_EDGE_INSET, DefaultView.BOTTOM_EDGE_INSET)

    createClippingPolygons: () ->
      DEG_TO_RAD = Math.PI/180
      RAD_TO_DEG = 180/Math.PI

      # we want the clipping polygons to reflect the actual visible portions, so we need to account for the slide bits that are cut off outside container bounds
      overflowAdjustment = @cutoffImageAmount - (@choppedPixels + @slantAdjustment) + 0
      @leftImagePoly = [
        [overflowAdjustment, 0]
        [@imgWidth - DefaultView.TOP_EDGE_INSET, 0]
        [@imgWidth - DefaultView.BOTTOM_EDGE_INSET, @imgHeight]
        [overflowAdjustment, @imgHeight]
        [overflowAdjustment, 0]
      ]

      @rightImagePoly = [
        [DefaultView.BOTTOM_EDGE_INSET, 0],
        [@imgWidth - overflowAdjustment, 0],
        [@imgWidth - overflowAdjustment, @imgHeight],
        [DefaultView.TOP_EDGE_INSET, @imgHeight],
        [DefaultView.BOTTOM_EDGE_INSET, 0],
      ]

      # do a little trig to calculate the angle of the relevant triangle; we'll need this to properly crop the background text box
      insetDiff = Math.abs(DefaultView.TOP_EDGE_INSET - DefaultView.BOTTOM_EDGE_INSET)
      bottomAngle = Math.atan(@imgHeight / insetDiff) * RAD_TO_DEG
      topAngle = Math.atan(insetDiff / @imgHeight) * RAD_TO_DEG
      @logToConsole "angles are [" + bottomAngle + "] / [" + topAngle + "]"

      textTriangleBase = DefaultView.TEXT_SHADOWBOX_HEIGHT / Math.tan(bottomAngle * DEG_TO_RAD)

      # topOfBox = 0
      topOfBox = @imgHeight - DefaultView.TEXT_SHADOWBOX_HEIGHT

      @leftTextPoly = [
        [overflowAdjustment, topOfBox],
        [@imgWidth - DefaultView.BOTTOM_EDGE_INSET + textTriangleBase, topOfBox],
        [@imgWidth - DefaultView.BOTTOM_EDGE_INSET, topOfBox + DefaultView.TEXT_SHADOWBOX_HEIGHT],
        [overflowAdjustment, topOfBox + DefaultView.TEXT_SHADOWBOX_HEIGHT]
      ]

      @rightTextPoly = [
        [DefaultView.TOP_EDGE_INSET + textTriangleBase, topOfBox],
        [@imgWidth - overflowAdjustment, topOfBox],
        [@imgWidth - overflowAdjustment, topOfBox + DefaultView.TEXT_SHADOWBOX_HEIGHT],
        [DefaultView.TOP_EDGE_INSET, topOfBox + DefaultView.TEXT_SHADOWBOX_HEIGHT]
      ]

    putDoorInOpenPosition: (doorEl, side) ->
      doorEl.css("left", (if side == BaseView.SIDE_LEFT then @leftDoorOpenDestination else @rightDoorOpenDestination))

    putDoorInClosedPosition: (doorEl, side) ->
      doorEl.css("left", (if side == BaseView.SIDE_LEFT then @leftDoorClosedDestination else @rightDoorClosedDestination))

    # do some math to figure out what's the offscreen and centered positions for each side of the show
    calculateSlideDestinations: ->
      # set this to adjust how far onscreen (positive number) the starting position for a door should be
      # debugAdjuster = 200
      debugAdjuster = 0

      centerOfDiv = @slideContainerDiv.width() / 2

      if (@renderMode == DefaultView.RENDER_MODE_BASIC)
        @leftDoorClosedDestination = centerOfDiv - @imgWidth
        @rightDoorClosedDestination = centerOfDiv
      else if (@renderMode == DefaultView.RENDER_MODE_DEFAULT or @renderMode == DefaultView.RENDER_MODE_CLIP_PATH)
        @leftDoorClosedDestination = centerOfDiv - (@imgWidth - @slantAdjustment) + @choppedPixels
        @rightDoorClosedDestination = centerOfDiv - @slantAdjustment - @choppedPixels

      # sometimes a gap is useful for debugging...
      gap = 0
      if gap > 0
        @leftDoorClosedDestination -= gap
        @rightDoorClosedDestination += gap

      # offscreen position is always the same
      @leftDoorOpenDestination = (-1 * @imgWidth) + debugAdjuster
      @rightDoorOpenDestination = @slideContainerDiv.width() - debugAdjuster


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
        if (@renderMode == DefaultView.RENDER_MODE_BASIC)
          imgDomEl.setAttribute('src', slide.imgUrl)
        else if (@renderMode == DefaultView.RENDER_MODE_DEFAULT or @renderMode == DefaultView.RENDER_MODE_CLIP_PATH)
          imgDomEl.setAttributeNS(BaseView.XLINK_NS, 'href', slide.imgUrl)
          imgDomEl.setAttribute('width', "100%")
          imgDomEl.setAttribute('height', "100%")

        # TODO? - sanitize this input? maybe allow a couple of tags but not full blown control...
        titleEl.html(slide.title)
        detailsEl.html(slide.details)

        if doAnimate
          doorEl.animate({
            "left": destinations[i] + "px",
          }, {
            "easing": DefaultView.EASE_FXN
            "duration": DefaultView.ANIMATION_LENGTH_MS
            # "progress": if i == 1 then ((a,p,r) => @onAnimationProgress(a,p,r)) else null
            "complete": (=> @onAnimationComplete())
          })
        else
          doorEl.css("left", destinations[i] + "px")

    ###
    onAnimationProgress: (anim, prog, remaining) ->
      @logToConsole "animating [" + prog + "]/[" + remaining "]"
    ###

    onAnimationComplete: ->
      @doorsThatFinishedAnimating++
      if @doorsThatFinishedAnimating == 2
        @currentlyAnimating = false
        # @logToConsole "ALL DOORS FINISHED!"
      else
        # @logToConsole "NOT DONE YET!"

    enforceAspectRatio: () ->
      # enforce aspect ratio
      @targetDiv.height(@targetDiv.width()/2)

    responsiveUpdate: (w, h) ->
      @logToConsole "viewport dimensions changed to [" + w + "x" + h + "...what shall we do about it?"
      @enforceAspectRatio()
      @slideContainerDiv.width(@targetDiv.width()).height(@targetDiv.height())
      @controlContainerDiv.width(@targetDiv.width()).height(@targetDiv.height())

      @precalcImageAdjustments()
      @createClippingPolygons()
      @calculateSlideDestinations()

      @resizeDoors()

    pseudoDestructor: ->
      @logToConsole "cleaning up custom default..."
      $("##{@targetDivName} > div").remove()
      # @targetDiv.css({ "background-color": "", "overflow": "", "position": "" })
      super

  return DefaultView
)
