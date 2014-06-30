# different views can do things like slice and dice the image, handle animating, etc.
# right now this is doing an awful lot...
define(["view/abstractview"], (AbstractView) ->
  class DefaultView extends AbstractView
    # currently hardcoded, and polygons are associated with the overall view
    # and not with individual items. If we allow different polys per pair, 
    # need to rethink this...
    @TOP_EDGE_INSET = 50
    @BOTTOM_EDGE_INSET = 90
    @TEXT_SHADOWBOX_HEIGHT = 100

    @EASE_FXN = "swing"
    @ANIMATION_LENGTH_MS = 900

    @SVG_NS = "http://www.w3.org/2000/svg"
    @XLINK_NS = "http://www.w3.org/1999/xlink"

    constructor: (@mainController, @targetDivName, @imgWidth, @imgHeight) ->
      console.log "constructing default view..."
      @targetDiv = $("##{@targetDivName}")

      pairCount = @mainController.appModel.getPairCount()

      @slideContainerDiv = $("<div/>").css({"width":@targetDiv.width(), "height":@targetDiv.height()}).attr("id", "slideContainer").appendTo(@targetDiv)
      @controlContainerDiv = $("<div/>").attr("id", "controlContainer").appendTo(@targetDiv)

      [@leftImagePoly, @rightImagePoly, @leftTextPoly, @rightTextPoly] = this.createClippingPolygons(@imgWidth, @imgHeight, DefaultView.TOP_EDGE_INSET, DefaultView.BOTTOM_EDGE_INSET, DefaultView.TEXT_SHADOWBOX_HEIGHT)
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


      for letter, i in ["A","B"]
        for side in ["left", "right"]
          elementSuffix = "_#{side}_#{i}"
          # add the necessary structure to the DOM
          doorEl = $("<div/>").attr("id", "door" + elementSuffix).appendTo(@slideContainerDiv)

          # now build out the svg stuff...this does NOT play nicely with JQuery so we just use plain JavaScript to construct it all
          # might want to separate this out to make this more explicit.
          # also todo - make some convenience functions for setting all these attribs
          
          # top level - svg
          svgEl = document.createElementNS(DefaultView.SVG_NS,"svg")
          svgEl.id = "mover" + elementSuffix
          svgEl.setAttribute("width", @imgWidth)
          svgEl.setAttribute("height", @imgHeight)
          svgEl.setAttribute("baseProfile", "full")
          svgEl.setAttribute("version", "1.2")
          (doorEl[0]).appendChild(svgEl)

          # svgEl contains a "defs" element...
          defsEl = document.createElementNS(DefaultView.SVG_NS, "defs")
          svgEl.appendChild(defsEl)

          # defs contains a mask...
          maskEl = document.createElementNS(DefaultView.SVG_NS, "mask")
          maskEl.id = "svgmask" + elementSuffix
          maskEl.setAttribute("maskUnits", "userSpaceOnUse")
          maskEl.setAttribute("maskContentUnits", "userSpaceOnUse")
          maskEl.setAttribute("transform", "scale(1)")
          defsEl.appendChild(maskEl)

          # and mask contain a polygon
          polygonEl = document.createElementNS(DefaultView.SVG_NS, "polygon")
          polygonEl.id = "maskpoly" + elementSuffix
          polygonEl.setAttribute("points", @translatePointsFromArrayToSVGNotation(if side == "left" then @leftImagePoly else @rightImagePoly))
          polygonEl.setAttribute("fill", "white")
          maskEl.appendChild(polygonEl)


          # ...and svgEl also contains an image
          imgEl = document.createElementNS(DefaultView.SVG_NS, "image")
          imgEl.id = "image" + elementSuffix
          # mask: "url(#svgmask" + elementSuffix
          maskAttrib = "url(#svgmask" + elementSuffix + ")"
          console.log "mask atrib [" + maskAttrib + "]"
          imgEl.setAttribute("mask", "url(#svgmask" + elementSuffix + ")")
          # imgEl.setAttribute("x", 0)
          # imgEl.setAttribute("y", 0)

          svgEl.appendChild(imgEl)


          ###
          # imgEl = $("<img/>").attr("id", "image" + elementSuffix).appendTo(doorEl)
          titleEl = $("<span/>").attr("id", "title" + elementSuffix).appendTo(doorEl)

          bbEl = $("<span/>").attr("id", "bb" + elementSuffix).appendTo(doorEl)
          blackBarStyle = {
            position: "absolute",
            width: @imgWidth + "px",
            left: "0px",
            bottom: "0px",
            height: "100px",
            background: "black",
            opacity: 0.5
          }

          bbEl.css(blackBarStyle)

          detailsEl = $("<span/>").attr("id", "details" + elementSuffix).appendTo(doorEl)
          ###

          # style things appropriately
          doorStyle = {
            position: "inherit",
            top: vertPos + "px",
            display: (if i == 0 then "block" else "none")
          }

          #svgStyle = {
            #width: @imgWidth
            #height: @imgHeight
          #}
          
          ###
          titleStyle = {
            position: "absolute",
            bottom: "100px",
            letterSpacing: "1px",
            font: "bold 30px/30px Helvetica, Sans-Serif"
          }

          detailsStyle = {
            position: "absolute",
            bottom: "60px",
            letterSpacing: "1px",
            font: "12px/12px Arial",
            color: "white"
          }
          ###

          # a few things are different based on which side door you are...
          ###
          textPadding = "140px"
          if (side == "left")
            titleStyle.right = textPadding
            detailsStyle.right = textPadding
            this.clipElement(@leftImagePoly, imgEl, "imagePolySVG_left")
            this.clipElement(@leftTextPoly, bbEl, "textPolySVG_left")
          else
            titleStyle.left = textPadding
            detailsStyle.left = textPadding
            this.clipElement(@rightImagePoly, imgEl, "imagePolySVG_right")
            this.clipElement(@rightTextPoly, bbEl, "textPolySVG_right")
          ###

          this.putDoorInOpenPosition(doorEl, side)

          doorEl.css(doorStyle)
          #svgEl.css(svgStyle)
          # titleEl.css(titleStyle)
          # detailsEl.css(detailsStyle)

          # and finally let's save things
          if (side == "left")
            @leftDoors.push(doorEl)
          else
            @rightDoors.push(doorEl)

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
      

    putDoorInOpenPosition: (doorEl, side) ->
      doorEl.css("left", (if side == "left" then @leftDoorOpenDestination else @rightDoorOpenDestination))

    putDoorInClosedPosition: (doorEl, side) ->
      doorEl.css("left", (if side == "left" then @leftDoorClosedDestination else @rightDoorClosedDestination))

    # do some math to figure out what's the offscreen and centered positions for each side of the show
    calculateSlideDestinations: ->
      slantAdjustment = Math.abs(DefaultView.TOP_EDGE_INSET - DefaultView.BOTTOM_EDGE_INSET) / 2
      choppedPixels = Math.min(DefaultView.TOP_EDGE_INSET, DefaultView.BOTTOM_EDGE_INSET)
      centerOfDiv = @slideContainerDiv.width() / 2

      @leftDoorClosedDestination = centerOfDiv - (@imgWidth - slantAdjustment) + choppedPixels
      @rightDoorClosedDestination = centerOfDiv - slantAdjustment - choppedPixels

      gap = 0
      if gap > 0
        @leftDoorClosedDestination -= gap
        @rightDoorClosedDestination += gap

      # set this to adjust how far onscreen (positive number) the starting position for a door should be
      # debugAdjuster = 200
      debugAdjuster = 0
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

        # imgEl.attr({
          # "xlink:href": slide.imgUrl
        # })

        console.log("!!!!!!!!!!!!!!!!!!!")
        console.log("!!!!!!! NS !!!!!!!!!")
        console.log("!!!!!!!!!!!!!!!!!!!")

        imgDomEl = document.getElementById("image" + suffix)
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

        @enforceDimensions()

    enforceDimensions: () ->
      # very weird bug that manifested when integrating into Reason module - the right slide
      # had varying width/height as it animated, causing it to appear to "grow" from the right
      # and slide in from the top. This is part of a fix for that problem
      console.log "REALLY ENfORCING DIMENIONS!!!"
      console.log "REALLY ENfORCING DIMENIONS!!!"
      console.log "REALLY ENfORCING DIMENIONS!!!"

      doors = [@leftDoors[@activeDoorIndex], @rightDoors[@activeDoorIndex]]
      for door in doors
        door.width(@imgWidth)
        door.height(@imgHeight)

      for foo in [ $("#mover_left_0"), $("#mover_right_0") ]
        foo.width(@imgWidth)
        foo.height(@imgHeight)


      # $("image_left_0").width(566)



      # imgDomEl = document.getElementById("image_left_0")
      # imgDomEl.setAttribute("width", "100%")
      # imgDomEl.setAttribute("height", "100%")
      # imgDomEl.style.width = "566px"
      # imgDomEl.style.height = "331px"
      # imgDomEl.width = 566
      # imgDomEl.height = 331

      # bar = document.getElementById("image_left_0")
      # console.log "got bar:"
      # console.log bar
      # bar.setAttributeNS(null, 'width', '566')
      # bar.setAttributeNS(null, 'height', '331')
      # bar.style.width = "300px"
      
      ###
      for foo in [ $("#image_left_0"), $("#image_right_0") ]
        foo.attr('width', @imgWidth)
        foo.attr('height', @imgHeight)
        # foo.width(@imgWidth)
        # foo.height(@imgHeight)
        console.log "image [" + foo.attr('id') + "] has width [" + foo.width() + "]"
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
