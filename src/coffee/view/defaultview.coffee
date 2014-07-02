# different views can do things like slice and dice the image, handle animating, etc.
# right now this is doing an awful lot...
define(["view/abstractview"], (AbstractView) ->
  class DefaultView extends AbstractView
    # currently hardcoded, and polygons are associated with the overall view
    # and not with individual items. If we allow different polys per pair, 
    # need to rethink this...
    @TOP_EDGE_INSET = 40
    @BOTTOM_EDGE_INSET = 90
    @TEXT_SHADOWBOX_HEIGHT = 100
    @TEXT_SHADOWBOX_OPACITY = 0.5

    @EASE_FXN = "swing"
    @ANIMATION_LENGTH_MS = 900

    @SVG_NS = "http://www.w3.org/2000/svg"
    @XLINK_NS = "http://www.w3.org/1999/xlink"

    constructor: (@mainController, @targetDivName, @imgWidth, @imgHeight) ->
      console.log "constructing default view..."
      @targetDiv = $("##{@targetDivName}")

      # @createCSSSelector(".tomOnTheFly", "width:100%; background-color:red")
      # styleDef = "position: absolute; left: 0px; bottom:0px; width:100%; height: " + DefaultView.TEXT_SHADOWBOX_HEIGHT + "px; -ms-filter: 'progid:DXImageTransform.Microsoft.Alpha(Opacity=" + (DefaultView.TEXT_SHADOWBOX_OPACITY * 100) + ")'; opacity: " + DefaultView.TEXT_SHADOWBOX_OPACITY + "; background-color:green"
      # @createCSSSelector(".blackbar_basic", styleDef
      # $("head").append("<style>.blackbar_basic { " + styleDef + " }</style>")

      ###
      css = ".blackbar_basic {" + styleDef + "}"
      head = document.head or document.getElementsByTagName('head')[0]
      style = document.createElement('style')
      style.type = 'text/css'
      if (style.styleSheet)
        style.styleSheet.cssText = css
      else
        style.appendChild(document.createTextNode(css))
      head.appendChild(style)
      ###


      # basic mode is for stuff like IE8 - skip the svg, don't do the fancy diagonal slice, etc.
      @basicMode = false
      if (true and !document.createElementNS)
        @basicMode = true

      pairCount = @mainController.appModel.getPairCount()

      @slideContainerDiv = $("<div/>").css({"width":@targetDiv.width(), "height":@targetDiv.height()}).attr("id", "slideContainer").appendTo(@targetDiv)
      @controlContainerDiv = $("<div/>").attr("id", "controlContainer").appendTo(@targetDiv)

      [@leftImagePoly, @rightImagePoly, @leftTextPoly, @rightTextPoly] = this.createClippingPolygons(@imgWidth, @imgHeight, DefaultView.TOP_EDGE_INSET, DefaultView.BOTTOM_EDGE_INSET, DefaultView.TEXT_SHADOWBOX_HEIGHT)

      # shift the y psitio down...
      # TODO - fix this, this is ugly and confusing should just be in the initial calculation. IT's a side-effect of
      # changing how the clipping stuff works.
      for tp in [@leftTextPoly, @rightTextPoly]
        for xy in tp
          xy[1] += (@imgHeight - DefaultView.TEXT_SHADOWBOX_HEIGHT)

      this.calculateSlideDestinations()
      # this.fleshOutInlineSVG()

      @slideContainerDiv.css({ "background-color": "gray", "overflow": "hidden", "position": "absolute" })

      vertPos = (@slideContainerDiv.height()/2) - (@imgHeight/2)

      @leftDoors = []
      @rightDoors = []

      # TODO - stop giving things unique id's and select them based on class/hierarchy perhaps? Or if not, at least break "door"/"title"/etc. out into consts

      # A/B lets us have two versions of the doors. One is always stuck in the middle, the other is used for animating.
      # we swap the z-order as necessary.

      console.log "SETUP WITH DIMENSIONS [" + @imgWidth + "]/[" + @imgHeight + "]..."

      halfDiv = @targetDiv.width()/2
      cutoffImageAmount = @imgWidth - halfDiv
      slantAdjustment = Math.abs(DefaultView.TOP_EDGE_INSET - DefaultView.BOTTOM_EDGE_INSET) / 2
      # choppedPixels = Math.min(DefaultView.TOP_EDGE_INSET, DefaultView.BOTTOM_EDGE_INSET)
      maxInset = Math.max(DefaultView.TOP_EDGE_INSET, DefaultView.BOTTOM_EDGE_INSET)

      for letter, i in ["A","B"]
        for side in ["left", "right"]
          elementSuffix = "_#{side}_#{i}"
          console.log "looping for [" + elementSuffix + "]"
          # add the necessary structure to the DOM
          doorEl = $("<div/>").attr("id", "door" + elementSuffix).appendTo(@slideContainerDiv)


          if side == "left"
            wordsX = cutoffImageAmount - maxInset + (slantAdjustment * 2)
          else
            wordsX = maxInset

          wordsWidth = halfDiv - (slantAdjustment * 2)
          titleHeight = 65


          if (@basicMode)
            console.log "RENDERING IN BASIC MODE"
            imgEl = document.createElement("img")
            imgEl.id = "image" + elementSuffix
            doorEl[0].appendChild(imgEl)

            bbEl = document.createElement("div")
            bbEl.className = "blackbar_basic"

            ###
            # bbEl.cssText = 'filter: progid:DXImageTransform.Microsoft.Alpha(Opacity=' + DefaultView.TEXT_SHADOWBOX_OPACITY*100 + ');'
            bbEl.style.position = "absolute"
            bbEl.style.left = "0px"
            bbEl.style.bottom = "0px"
            bbEl.style.width = "100%"
            bbEl.style["background-color"] = "black"
            bbEl.style.height = DefaultView.TEXT_SHADOWBOX_HEIGHT + "px"
            # bbEl.className = "tomOnTheFly"
            # bbEl.style["background-color"] = "black"
            # bbEl.style["-ms-filter"] = "progid:DXImageTransform.Microsoft.Alpha(Opacity=" + (DefaultView.TEXT_SHADOWBOX_OPACITY*100)   + ")"
            # bbEl.style.filters.item("DXImageTransform.Microsoft.Alpha").opacity = DefaultView.TEXT_SHADOWBOX_OPACITY * 100

            foo = '<div id="innerFoo" style="width:100%; height:100%; -ms-filter: progid:DXImageTransform.Microsoft.Alpha(Opacity=50);"></div>'
            bbEl.innerHTML = foo

            bbEl.style.opacity = DefaultView.TEXT_SHADOWBOX_OPACITY
            bbEl.style.height = DefaultView.TEXT_SHADOWBOX_HEIGHT + "px"
            ###
            doorEl[0].appendChild(bbEl)
          else
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
              points: @translatePointsFromArrayToSVGNotation(if side == "left" then @leftImagePoly else @rightImagePoly)
              fill: "white"
            })
            maskEl.appendChild(polygonEl)

            # ...and svgEl also contains an image
            imgEl = document.createElementNS(DefaultView.SVG_NS, "image")
            imgEl.id = "image" + elementSuffix
            @addAttributeHelper(imgEl, {
              mask: "url(#svgmask" + elementSuffix + ")"
            })
            svgEl.appendChild(imgEl)

            bbEl = document.createElementNS(DefaultView.SVG_NS, "polygon")
            bbEl.id = "bb" + elementSuffix
            @addAttributeHelper(bbEl, {
              points: @translatePointsFromArrayToSVGNotation(if side == "left" then @leftTextPoly else @rightTextPoly)
              fill: "black"
              "fill-opacity": DefaultView.TEXT_SHADOWBOX_OPACITY
            })
            svgEl.appendChild(bbEl)

            ###
            titleEl = @addTextToSVG(svgEl,
                                    "title" + elementSuffix,
                                    wordsX
                                    @imgHeight - DefaultView.TEXT_SHADOWBOX_HEIGHT - titleHeight,
                                    wordsWidth
                                    titleHeight)

            detailsEl = @addTextToSVG(svgEl,
                                    "details" + elementSuffix,
                                    wordsX
                                    @imgHeight - DefaultView.TEXT_SHADOWBOX_HEIGHT,
                                    wordsWidth
                                    DefaultView.TEXT_SHADOWBOX_HEIGHT)
            ###
            


            # end of normal styling. CoffeeScript's lack of brackets is a little annoying sometimes
          this.putDoorInOpenPosition(doorEl, side)


          titleEl = $("<div/>").attr("id", "title" + elementSuffix).appendTo(doorEl)
          detailsEl = $("<div/>").attr("id", "details" + elementSuffix).appendTo(doorEl)

          ###
          detailsEl = $("<span/>").attr("id", "details" + elementSuffix).appendTo(doorEl)
          ###

          # style things appropriately

          wordsAlignment = if side == "left" then "right" else "left"
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

          # a few things are different based on which side door you are...
          ###
          textPadding = 140
          if (side == "left")
            # titleStyle.right = textPadding
            # detailsStyle.right = textPadding
            # this.clipElement(@leftImagePoly, imgEl, "imagePolySVG_left")
            # this.clipElement(@leftTextPoly, bbEl, "textPolySVG_left")
          else
            # titleStyle.left = textPadding
            # detailsStyle.left = textPadding
            # this.clipElement(@rightImagePoly, imgEl, "imagePolySVG_right")
            # this.clipElement(@rightTextPoly, bbEl, "textPolySVG_right")
          ###

          doorStyle = {
            position: "inherit",
            top: vertPos + "px",
            display: (if i == 0 then "block" else "none")
          }
          doorEl.css(doorStyle)
          titleEl.css(titleStyle)
          detailsEl.css(detailsStyle)


          # and finally let's save things
          if (side == "left")
            @leftDoors.push(doorEl)
          else
            @rightDoors.push(doorEl)

          console.log "end of this bit"
          

      controlsEl = $("<div/>").css({"position": "relative", "top":@slideContainerDiv.height()}).attr("id", "barndoorControls").appendTo(@controlContainerDiv)
      # listEl = $("<ul/>").appendTo(controlsEl)
      # for i in [0..@pairCount-1]
      for i in [0..pairCount-1]
        # liEl = $("<li/>").appendTo(listEl)
        # liEl.html("SLIDE " + (i+1))
        console.log "need a control for [" + i + "]"
        jumpEl = $("<span/>").attr("class", "slideJumpControl").appendTo(controlsEl)

        jumpElStyle = {
          # width: 50
          # height: 50
          "background-color": "red"
          cursor: "hand"
          margin: 20
          # padding: 20
        }

        classHook = this
        jumpEl.click(() ->
          if classHook.currentlyAnimating
            # console.log "not done with previous animation..."
          else
            classHook.jumpToIndex($(this).index())
        )

        jumpEl.css(jumpElStyle)
        jumpEl.html("slide_" + (i+1))

      @playPauseEl = $("<span/>").css({cursor: "hand", "background-color": "grey"}).appendTo(controlsEl)
      @playPauseEl.click(() ->
        classHook.togglePlayPause()
      )
      @reRenderJumpControls(@mainController.appModel.activePairIndex)

      @activeDoorIndex = 0
      # setTimeout((=> @cropImagesDelayed()), 2000)
      ###
      blackBarEl = $("<span/>").attr('id', 'blackBarFoo').appendTo(@targetDiv)
      blackBarStyle = {
        position: "absolute",
        width: "100%",
        left: "0px",
        bottom: "0px",
        height: "110px",
        background: "red",
        opacity: 0.5
      }
      blackBarEl.css(blackBarStyle)
      ###

    ###
    cropImagesDelayed: ->
      console.log "DELAYED here we go [" + this + "]"
      for letter, i in ["A","B"]
        for side in ["left", "right"]
          elementSuffix = "_#{side}_#{i}"
          imgEl = $("#image" + elementSuffix);
          console.log "IMG EL IS [" + imgEl.attr('id') + "]..."
          if (side == "left")
            this.clipElement(@leftImagePoly, imgEl, "polySVG_left")
          else
            this.clipElement(@rightImagePoly, imgEl, "polySVG_right")
    ###

    ### 
    fleshOutInlineSVG: ->
      for side in ["left","right"]
        $("#imagePolySVG_#{side} > polygon").attr("points", @translatePointsFromArrayToSVGNotation((if side == "left" then @leftImagePoly else @rightImagePoly)))
        $("#textPolySVG_#{side} > polygon").attr("points", @translatePointsFromArrayToSVGNotation((if side == "left" then @leftTextPoly else @rightTextPoly)))
    ###

    addAttributeHelper: (o, attribs) ->
      for n, v of attribs
        o.setAttribute(n, v)

    ###
    addTextToSVG: (container, idString, xPos, yPos, width, height, debugColor = null) ->
      foId = "fo_" + idString

      foreignObj = document.createElementNS(DefaultView.SVG_NS, "foreignObject")
      foreignObj.id = foId
      @addAttributeHelper(foreignObj, {
        class: "node"
        width: width
        height: height
        x: xPos
        y: yPos
      })
      if debugColor != null then foreignObj.style["background-color"] = debugColor
      container.appendChild(foreignObj)

      textHolder = $("<div/>").attr({
        id: idString
      }).css({
        width: width
        height: height
      }).appendTo($("#" + foId))

      return textHolder
    ###
      

    putDoorInOpenPosition: (doorEl, side) ->
      doorEl.css("left", (if side == "left" then @leftDoorOpenDestination else @rightDoorOpenDestination))

    putDoorInClosedPosition: (doorEl, side) ->
      doorEl.css("left", (if side == "left" then @leftDoorClosedDestination else @rightDoorClosedDestination))

    # do some math to figure out what's the offscreen and centered positions for each side of the show
    calculateSlideDestinations: ->
      # set this to adjust how far onscreen (positive number) the starting position for a door should be
      # debugAdjuster = 200
      debugAdjuster = 0

      centerOfDiv = @slideContainerDiv.width() / 2

      if (@basicMode)
        @leftDoorClosedDestination = centerOfDiv - @imgWidth
        @rightDoorClosedDestination = centerOfDiv
      else
        slantAdjustment = Math.abs(DefaultView.TOP_EDGE_INSET - DefaultView.BOTTOM_EDGE_INSET) / 2
        choppedPixels = Math.min(DefaultView.TOP_EDGE_INSET, DefaultView.BOTTOM_EDGE_INSET)

        @leftDoorClosedDestination = centerOfDiv - (@imgWidth - slantAdjustment) + choppedPixels
        @rightDoorClosedDestination = centerOfDiv - slantAdjustment - choppedPixels

      # sometimes a gap is useful for debugging...
      gap = 0
      if gap > 0
        @leftDoorClosedDestination -= gap
        @rightDoorClosedDestination += gap

      # offscreen position is always the same
      @leftDoorOpenDestination = (-1 * @imgWidth) + debugAdjuster
      @rightDoorOpenDestination = @slideContainerDiv.width() - debugAdjuster


    renderInitialView: (pair) ->
      console.log "rendering with [" + pair + "]..."
      @leftSlide = pair.leftSlide
      @rightSlide = pair.rightSlide

      this.positionSlides(false)

    updatePlayPauseStatus: (isPlaying) ->
      @playPauseEl.html(if isPlaying then "PAUSE" else "PLAY")

    reRenderJumpControls: (index) ->
      console.log "update jumpers [" + index + "]"
      # spans = $("#barndoorControls > span")
      spans = $("#barndoorControls > span.slideJumpControl")
      console.log spans
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

      sides = [ "left", "right" ]
      oldDoors = [@leftDoors[@inactiveDoorIndex], @rightDoors[@inactiveDoorIndex]]

      if reversing
        # put the new slides behind the current ones, in the middle, and "open" the barn doors
        for doorEl, i in [@leftDoors[@activeDoorIndex], @rightDoors[@activeDoorIndex]]
          doorEl.css("display", "block")
          @stackElements(oldDoors[i], doorEl)
          @putDoorInClosedPosition(doorEl, sides[i])
        @positionSlides(true, false)
      else
        # put the new slides on top of the current ones and offscreen, and "close" the barn doors
        for doorEl, i in [@leftDoors[@activeDoorIndex], @rightDoors[@activeDoorIndex]]
          doorEl.css("display", "block")
          @putDoorInOpenPosition(doorEl, sides[i])
          @stackElements(doorEl, oldDoors[i])
        @positionSlides()

    positionSlides: (doAnimate = true, closeSlides = true) ->
      # @leftImgElement.attr("src", "/barndoor/images/sayles.jpg")

      sides = [ "left", "right" ]
      slides = [ @leftSlide, @rightSlide ]
      destinations = if closeSlides then [ @leftDoorClosedDestination, @rightDoorClosedDestination ] else [ @leftDoorOpenDestination, @rightDoorOpenDestination ]

      animaters = if closeSlides then [ @leftDoors[@activeDoorIndex], @rightDoors[@activeDoorIndex] ] else [ @leftDoors[@inactiveDoorIndex], @rightDoors[@inactiveDoorIndex] ]

      @currentlyAnimating = doAnimate
      @doorsThatFinishedAnimating = 0
      for doorEl, i in animaters
        suffix = "_" + sides[i] + "_" + @activeDoorIndex
        slide = slides[i]

        # imgEl = $("#image" + suffix)
        titleEl = $("#title" + suffix)
        detailsEl = $("#details" + suffix)

        # imgEl.attr("src", slide.imgUrl)
        # imgEl.css({width:@imgWidth, height:@imgHeight})
        # imgEl.attr("xlink:href", slide.imgUrl)

        imgDomEl = document.getElementById("image" + suffix)
        if (@basicMode)
          imgDomEl.setAttribute('src', slide.imgUrl)
        else
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

        # doesnt seem necessary since reworking how doors are built
        # @enforceDimensions()

    ###
    enforceDimensions: () ->
      # very weird bug that manifested when integrating into Reason module - the right slide
      # had varying width/height as it animated, causing it to appear to "grow" from the right
      # and slide in from the top. This is part of a fix for that problem

      doors = [@leftDoors[@activeDoorIndex], @rightDoors[@activeDoorIndex]]
      for door in doors
        door.width(@imgWidth)
        door.height(@imgHeight)

      for foo in [ $("#mover_left_0"), $("#mover_right_0") ]
        foo.width(@imgWidth)
        foo.height(@imgHeight)
    ###
      
    ###
    onAnimationProgress: (anim, prog, remaining) ->
      console.log "animating [" + prog + "]/[" + remaining "]"
    ###

    onAnimationComplete: ->
      @doorsThatFinishedAnimating++
      if @doorsThatFinishedAnimating == 2
        @currentlyAnimating = false
        # console.log "ALL DOORS FINISHED!"
      else
        # console.log "NOT DONE YET!"

    pseudoDestructor: ->
      console.log "cleaning up custom default..."
      $("##{@targetDivName} > div").remove()
      # @targetDiv.css({ "background-color": "", "overflow": "", "position": "" })
      super

  return DefaultView
)
