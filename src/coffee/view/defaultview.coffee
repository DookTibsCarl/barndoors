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

    @SVG_NS = "http://www.w3.org/2000/svg"
    @XLINK_NS = "http://www.w3.org/1999/xlink"

    constructor: (@mainController, @targetDivName, @imgWidth, @imgHeight) ->
      @logToConsole "constructing default view..."
      @logToConsole "sides are [" + BaseView.SIDES + "]"
      @targetDiv = $("##{@targetDivName}")

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

      $("#debugUserAgent").html(nua)
      $("#debugRenderMode").html(@renderMode)

      pairCount = @mainController.appModel.getPairCount()

      @slideContainerDiv = $("<div/>").css({"width":@targetDiv.width(), "height":@targetDiv.height()}).attr("id", "slideContainer").appendTo(@targetDiv)
      @controlContainerDiv = $("<div/>").css({"position": "absolute", "width":@targetDiv.width()}).attr("id", "controlContainer").appendTo(@targetDiv)

      [@leftImagePoly, @rightImagePoly, @leftTextPoly, @rightTextPoly] = this.createClippingPolygons(@imgWidth, @imgHeight, DefaultView.TOP_EDGE_INSET, DefaultView.BOTTOM_EDGE_INSET, DefaultView.TEXT_SHADOWBOX_HEIGHT)

      # a couple of dimensions/calculations are used in a number of places - let's just do them up front.
      @halfDiv = @targetDiv.width()/2
      @cutoffImageAmount = @imgWidth - @halfDiv
      @slantAdjustment = Math.abs(DefaultView.TOP_EDGE_INSET - DefaultView.BOTTOM_EDGE_INSET) / 2
      @choppedPixels = Math.min(DefaultView.TOP_EDGE_INSET, DefaultView.BOTTOM_EDGE_INSET)
      @maxInset = Math.max(DefaultView.TOP_EDGE_INSET, DefaultView.BOTTOM_EDGE_INSET)

      @calculateSlideDestinations()

      @slideContainerDiv.css({ "background-color": "gray", "overflow": "hidden", "position": "absolute" })

      vertPos = (@slideContainerDiv.height()/2) - (@imgHeight/2)

      @leftDoors = []
      @rightDoors = []

      # TODO - stop giving things unique id's and select them based on class/hierarchy perhaps? Or if not, at least break "door"/"title"/etc. out into consts

      # add the clip-path polygons used by the clip_path rendering style
      if (@renderMode == DefaultView.RENDER_MODE_BROWSER_TOO_OLD)
        @slideContainerDiv.remove()
        # @slideContainerDiv.html("sorry, browser too old")
        @controlContainerDiv.remove()
        
      else if (@renderMode == DefaultView.RENDER_MODE_CLIP_PATH)
        for side, i in BaseView.SIDES
          poly = @translatePointsFromArrayToSVGNotation(if side == BaseView.SIDE_LEFT then @leftImagePoly else @rightImagePoly)
          svgEl = document.createElementNS(DefaultView.SVG_NS,"svg")
          @addAttributeHelper(svgEl, {
            width: 0
            height: 0
          })
          (@slideContainerDiv[0]).appendChild(svgEl)

          defsEl = document.createElementNS(DefaultView.SVG_NS, "defs")
          svgEl.appendChild(defsEl)

          clipPathEl = document.createElementNS(DefaultView.SVG_NS, "clipPath")
          @addAttributeHelper(clipPathEl, {
            id: side + "_clip_path"
          })
          defsEl.appendChild(clipPathEl)

          polygonEl = document.createElementNS(DefaultView.SVG_NS, "polygon")
          @addAttributeHelper(polygonEl, {
            points: poly
          })
          clipPathEl.appendChild(polygonEl)


      for letter, i in ["A","B"]
        for side in BaseView.SIDES
          elementSuffix = "_#{side}_#{i}"
          @logToConsole "looping for [" + elementSuffix + "]"
          # add the necessary structure to the DOM
          doorEl = $("<div/>").attr("id", "door" + elementSuffix).appendTo(@slideContainerDiv)


          if side == BaseView.SIDE_LEFT
            wordsX = @cutoffImageAmount - @maxInset + (@slantAdjustment * 2)
          else
            wordsX = @maxInset

          wordsWidth = @halfDiv - (@slantAdjustment * 2)
          titleHeight = 65

          if (@renderMode == DefaultView.RENDER_MODE_BASIC)
            @logToConsole "RENDERING IN BASIC MODE"
            imgEl = document.createElement("img")
            imgEl.id = "image" + elementSuffix
            doorEl[0].appendChild(imgEl)

            bbEl = document.createElement("div")
            bbEl.className = "blackbar_basic"

            doorEl[0].appendChild(bbEl)
          else if (@renderMode == DefaultView.RENDER_MODE_DEFAULT or @renderMode == DefaultView.RENDER_MODE_CLIP_PATH)
            # now build out the svg stuff...this does NOT play nicely with JQuery so we just use plain JavaScript to construct it all
            # might want to separate this out to make this more explicit.
            # also todo - make some convenience functions for setting all these attribs

            # top level - svg
            svgEl = document.createElementNS(DefaultView.SVG_NS,"svg")
            svgEl.id = "mover" + elementSuffix
            @addAttributeHelper(svgEl, {
              width: @imgWidth
              height: @imgHeight
              baseProfile: "full"
              version: "1.2"
            })
            (doorEl[0]).appendChild(svgEl)

            if (@renderMode == DefaultView.RENDER_MODE_DEFAULT)
              # svgEl contains a "defs" element...
              defsEl = document.createElementNS(DefaultView.SVG_NS, "defs")
              svgEl.appendChild(defsEl)

              # defs contains a mask...
              maskEl = document.createElementNS(DefaultView.SVG_NS, "mask")
              maskEl.id = "svgmask" + elementSuffix
              @addAttributeHelper(maskEl, {
                maskUnits: "userSpaceOnUse"
                maskContentUnits: "userSpaceOnUse"
                transform: "scale(1)"
              })
              defsEl.appendChild(maskEl)

              # and mask contain a polygon
              polygonEl = document.createElementNS(DefaultView.SVG_NS, "polygon")
              polygonEl.id = "maskpoly" + elementSuffix
              @addAttributeHelper(polygonEl, {
                points: @translatePointsFromArrayToSVGNotation(if side == BaseView.SIDE_LEFT then @leftImagePoly else @rightImagePoly)
                fill: "white"
              })
              maskEl.appendChild(polygonEl)
            # else if (@renderMode == DefaultView.RENDER_MODE_CLIP_PATH)
              # no special handling required

            # ...and svgEl also contains an image
            imgEl = document.createElementNS(DefaultView.SVG_NS, "image")
            imgEl.id = "image" + elementSuffix

            if (@renderMode == DefaultView.RENDER_MODE_DEFAULT)
              @addAttributeHelper(imgEl, {
                mask: "url(#svgmask" + elementSuffix + ")"
              })
            else if (@renderMode == DefaultView.RENDER_MODE_CLIP_PATH)
              @addAttributeHelper(imgEl, {
                "clip-path": "url(#" + side + "_clip_path)"
              })

            svgEl.appendChild(imgEl)

            bbEl = document.createElementNS(DefaultView.SVG_NS, "polygon")
            bbEl.id = "bb" + elementSuffix
            @addAttributeHelper(bbEl, {
              points: @translatePointsFromArrayToSVGNotation(if side == BaseView.SIDE_LEFT then @leftTextPoly else @rightTextPoly)
              fill: "black"
              "fill-opacity": DefaultView.TEXT_SHADOWBOX_OPACITY
            })
            svgEl.appendChild(bbEl)


            offscreenShifter = @imgWidth - (@targetDiv.width() / 2) - (@choppedPixels + @slantAdjustment) + 0
            # offscreenShifter = @cutoffImageAmount - (@choppedPixels + @slantAdjustment) + 0

            strokeColor = "white"
            tAdj = 0
            bAdj = 0
            if (side == BaseView.SIDE_LEFT)
              lAdj = offscreenShifter
              rAdj = 0
              # strokeColor = if (i == 0) then "red" else "yellow"
            else
              lAdj = 0
              rAdj = -1 * offscreenShifter
              # strokeColor = if (i == 0) then "purple" else "green"

            outlineEl = document.createElementNS(DefaultView.SVG_NS, "polyline")
            @addAttributeHelper(outlineEl, {
              points: @translatePointsFromArrayToSVGNotation(@squeezePoly((if side == BaseView.SIDE_LEFT then @leftImagePoly else @rightImagePoly), tAdj, bAdj, lAdj, rAdj))
              # points: @translatePointsFromArrayToSVGNotation(if side == BaseView.SIDE_LEFT then [@leftImagePoly[1], @leftImagePoly[2]] else ([@rightImagePoly[0], @rightImagePoly[3]]))
              style: "fill:none; stroke:" + strokeColor + "; stroke-width:3"
            })
            svgEl.appendChild(outlineEl)
            # end of normal styling. CoffeeScript's lack of brackets is a little annoying sometimes

          this.putDoorInOpenPosition(doorEl, side)

          titleEl = $("<div/>").attr("id", "title" + elementSuffix).appendTo(doorEl)
          detailsEl = $("<div/>").attr("id", "details" + elementSuffix).appendTo(doorEl)

          # style things appropriately

          wordsAlignment = if side == BaseView.SIDE_LEFT then "right" else "left"
          titleStyle = {
            # "background-color": "green"
            position: "absolute"
            bottom: DefaultView.TEXT_SHADOWBOX_HEIGHT
            # top: @imgHeight - DefaultView.TEXT_SHADOWBOX_HEIGHT - titleHeight
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
          

      # @addControls(DefaultView.CONTROL_MODE_PAGINATED)
      @addControls(DefaultView.CONTROL_MODE_PREV_NEXT)

      @activeDoorIndex = 0

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

    addAttributeHelper: (o, attribs) ->
      for n, v of attribs
        o.setAttribute(n, v)

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
          imgDomEl.setAttributeNS(DefaultView.XLINK_NS, 'href', slide.imgUrl)
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

    pseudoDestructor: ->
      @logToConsole "cleaning up custom default..."
      $("##{@targetDivName} > div").remove()
      # @targetDiv.css({ "background-color": "", "overflow": "", "position": "" })
      super

  return DefaultView
)
