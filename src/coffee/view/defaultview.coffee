# different views can do things like slice and dice the image, handle animating, etc.
# right now this is doing an awful lot...
# define(["jquery", "dist/js/view/abstractview"], (jq, AbstractView) ->
define(["dist/js/view/abstractview"], (AbstractView) ->
  class DefaultView extends AbstractView
    # currently hardcoded, and polygons are associated with the overall view
    # and not with individual items. If we allow different polys per pair, 
    # need to rethink this...
    @TOP_EDGE_INSET = 50
    @BOTTOM_EDGE_INSET = 90
    @TEXT_SHADOWBOX_HEIGHT = 100

    @EASE_FXN = "swing"
    @ANIMATION_LENGTH_MS = 900

    constructor: (@targetDivName, @imgWidth, @imgHeight) ->
      console.log "constructing default view!"
      @targetDiv = $("##{@targetDivName}")

      [@leftImagePoly, @rightImagePoly, @leftTextPoly, @rightTextPoly] = this.createClippingPolygons(@imgWidth, @imgHeight, DefaultView.TOP_EDGE_INSET, DefaultView.BOTTOM_EDGE_INSET, DefaultView.TEXT_SHADOWBOX_HEIGHT)
      this.calculateCenteredSlidePositions()
      this.fleshOutInlineSVG()

      @targetDiv.css({ "background-color": "gray", "overflow": "hidden", "position": "absolute" })

      vertPos = (@targetDiv.height()/2) - (@imgHeight/2)

      @leftDoors = []
      @rightDoors = []

      # TODO - stop giving things unique id's and select them based on class/hierarchy perhaps? Or if not, at least break "door"/"title"/etc. out into consts

      # A/B lets us have two versions of the doors. One is always stuck in the middle, the other is used for animating.
      # we swap the z-order as necessary.

      for letter, i in ["A","B"]
        for side in ["left", "right"]
          elementSuffix = "_#{side}_#{i}"
          # add the necessary structure to the DOM
          doorEl = $("<div/>").attr("id", "door" + elementSuffix).appendTo(@targetDiv)
          imgEl = $("<img/>").attr("id", "image" + elementSuffix).appendTo(doorEl)
          titleEl = $("<span/>").attr("id", "title" + elementSuffix).appendTo(doorEl)

          bbEl = $("<span/>").attr("id", "title" + elementSuffix).appendTo(doorEl)
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

          # style things appropriately
          doorStyle = {
            position: "inherit",
            top: vertPos + "px",
            display: (if i == 0 then "block" else "none")
          }
          
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

          # a few things are different based on which side door you are...
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

          this.putDoorInOpenPosition(doorEl, side)

          doorEl.css(doorStyle)
          titleEl.css(titleStyle)
          detailsEl.css(detailsStyle)

          # and finally let's save things
          if (side == "left")
            @leftDoors.push(doorEl)
          else
            @rightDoors.push(doorEl)

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

    fleshOutInlineSVG: ->
      ### 
      svgEl = $("<svg/>").attr({"width": 0, "height": 0}).appendTo($(document.body))
      for side in ["left","right"]
        pathEl = $("<clipPath/>").attr("id", "imagePolySVG_" + side).appendTo(svgEl)
        polyEl = $("<polygon/>").attr("points", @translatePointsFromArrayToSVGNotation((if side == "left" then @leftImagePoly else @rightImagePoly))).appendTo(pathEl)

        pathEl = $("<clipPath/>").attr("id", "textPolySVG_" + side).appendTo(svgEl)
        polyEl = $("<polygon/>").attr("points", @translatePointsFromArrayToSVGNotation((if side == "left" then @leftTextPoly else @rightTextPoly))).appendTo(pathEl)
      ###
      for side in ["left","right"]
        $("#imagePolySVG_#{side} > polygon").attr("points", @translatePointsFromArrayToSVGNotation((if side == "left" then @leftImagePoly else @rightImagePoly)))
        $("#textPolySVG_#{side} > polygon").attr("points", @translatePointsFromArrayToSVGNotation((if side == "left" then @leftTextPoly else @rightTextPoly)))
      

    putDoorInOpenPosition: (doorEl, side) ->
      # set this to adjust how far onscreen (positive number) the starting position for a door should be
      # debugAdjuster = 200
      debugAdjuster = 0

      if (side == "left")
        leftPos = ((-1 * @imgWidth) + debugAdjuster) + "px"
      else
        leftPos = (@targetDiv.width() - debugAdjuster) + "px"

      doorEl.css("left", leftPos)
      

    calculateCenteredSlidePositions: ->
      slantAdjustment = Math.abs(DefaultView.TOP_EDGE_INSET - DefaultView.BOTTOM_EDGE_INSET) / 2
      choppedPixels = Math.min(DefaultView.TOP_EDGE_INSET, DefaultView.BOTTOM_EDGE_INSET)
      centerOfDiv = @targetDiv.width() / 2

      @leftDoorDestination = centerOfDiv - (@imgWidth - slantAdjustment) + choppedPixels
      @rightDoorDestination = centerOfDiv - slantAdjustment - choppedPixels

      gap = 0
      if gap > 0
        @leftDoorDestination -= gap
        @rightDoorDestination += gap


    renderInitialView: (pair) ->
      console.log "rendering with [" + pair + "]..."
      @leftSlide = pair.leftSlide
      @rightSlide = pair.rightSlide

      this.centerSlides(false)

    showNextPair: (pair) ->
      @inactiveDoorIndex = @activeDoorIndex

      @activeDoorIndex++
      if (@activeDoorIndex >= @leftDoors.length)
        @activeDoorIndex = 0

      @leftSlide = pair.leftSlide
      @rightSlide = pair.rightSlide

      sides = [ "left", "right" ]
      oldDoors = [@leftDoors[@inactiveDoorIndex], @rightDoors[@inactiveDoorIndex]]
      for doorEl, i in [@leftDoors[@activeDoorIndex], @rightDoors[@activeDoorIndex]]
        doorEl.css("display", "block")
        @putDoorInOpenPosition(doorEl, sides[i])
        @stackElements(doorEl, oldDoors[i])
      @centerSlides()

    centerSlides: (doAnimate = true) ->
      # @leftImgElement.attr("src", "/barndoor/images/sayles.jpg")

      sides = [ "left", "right" ]
      slides = [ @leftSlide, @rightSlide ]
      destinations = [ @leftDoorDestination, @rightDoorDestination ]
      @doorsShut = 0
      for doorEl, i in [@leftDoors[@activeDoorIndex], @rightDoors[@activeDoorIndex]]
        suffix = "_" + sides[i] + "_" + @activeDoorIndex
        slide = slides[i]

        imgEl = $("#image" + suffix)
        titleEl = $("#title" + suffix)
        detailsEl = $("#details" + suffix)

        imgEl.attr("src", slide.imgUrl)
        titleEl.css("color", slide.fontColor)
        # TODO - should sanitize this input; maybe allow a couple of tags but not full blown control...
        titleEl.html(slide.title)
        detailsEl.html(slide.details)

        if doAnimate
          doorEl.animate({
            "left": destinations[i] + "px",
          }, DefaultView.ANIMATION_LENGTH_MS, DefaultView.EASE_FXN, (=> @onAnimationComplete()))
        else
          doorEl.css("left", destinations[i] + "px")

    onAnimationComplete: ->
      @doorsShut++
      if @doorsShut == 2
        # console.log "ALL DOORS CLOSED!"
      else
        # console.log "NOT DONE YET!"

    pseudoDestructor: ->
      console.log "cleaning up custom default..."
      $("##{@targetDivName} > div").remove()
      @targetDiv.css({ "background-color": "", "overflow": "", "position": "" })
      super

  return DefaultView
)
