# different views can do things like slice and dice the image, handle animating, etc.
# right now this is doing an awful lot...
define(["jquery", "js/app/abstractview"], (jq, AbstractView) ->
  class DefaultView extends AbstractView
    # currently hardcoded, and polygons are associated with the overall view
    # and not with individual items. If we allow different polys per pair, 
    # need to rethink this...
    @TOP_EDGE_INSET = 50
    @BOTTOM_EDGE_INSET = 90

    @EASE_FXN = "swing"
    @ANIMATION_LENGTH_MS = 900

    constructor: (@targetDivName, @imgWidth, @imgHeight) ->
      console.log "building default view a..."
      @targetDiv = $("##{@targetDivName}")

      [@leftPoly, @rightPoly] = this.createClippingPolygons(@imgWidth, @imgHeight, DefaultView.TOP_EDGE_INSET, DefaultView.BOTTOM_EDGE_INSET)
      this.calculateCenteredSlidePositions()

      @targetDiv.css({ "background-color": "gray", "overflow": "hidden", "position": "absolute" })

      # [@leftDoorElA, @leftDoorElB, @rightDoorElA, @rightDoorElB] = 

      vertPos = (@targetDiv.height()/2) - (@imgHeight/2)

      @leftDoors = []
      @rightDoors = []

      # A/B lets us have two versions of the doors. One is always stuck in the middle, the other is used for animating.
      # we swap the z-order as necessary.
      for letter, i in ["A","B"]
        for side in ["left", "right"]
          elementSuffix = "_#{side}_#{i}"
          # add the necessary structure to the DOM
          doorEl = $("<div/>").attr("id", "door" + elementSuffix).appendTo(@targetDiv)
          imgEl = $("<img/>").attr("id", "image" + elementSuffix).appendTo(doorEl)
          titleEl = $("<span/>").attr("id", "title" + elementSuffix).appendTo(doorEl)

          # style things appropriately
          doorStyle = {
            position: "inherit",
            top: vertPos + "px",
            display: (if i == 0 then "block" else "none")
          }
          
          titleStyle = {
            position: "absolute",
            bottom: "20px",
            letterSpacing: "1px",
            font: "bold 24px/24px Helvetica, Sans-Serif"
          }

          # a few things are different based on which side door you are...
          textPadding = "140px"
          if (side == "left")
            titleStyle.right = textPadding
            this.clipImage(@leftPoly, imgEl)
          else
            titleStyle.left = textPadding
            this.clipImage(@rightPoly, imgEl)

          this.putDoorInOpenPosition(doorEl, side)

          doorEl.css(doorStyle)
          titleEl.css(titleStyle)

          # and finally let's save things
          if (side == "left")
            @leftDoors.push(doorEl)
          else
            @rightDoors.push(doorEl)

      @activeDoorIndex = 0

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
      oldIdx = @activeDoorIndex

      @activeDoorIndex++
      if (@activeDoorIndex >= @leftDoors.length)
        @activeDoorIndex = 0

      @leftSlide = pair.leftSlide
      @rightSlide = pair.rightSlide

      sides = [ "left", "right" ]
      oldDoors = [@leftDoors[oldIdx], @rightDoors[oldIdx]]
      for doorEl, i in [@leftDoors[@activeDoorIndex], @rightDoors[@activeDoorIndex]]
        doorEl.css("display", "block")
        @putDoorInOpenPosition(doorEl, sides[i])
        @stackElements(doorEl, oldDoors[i])
      @centerSlides()

    centerSlides: (doAnimate = true) ->
      console.log "do something neat"
      # @leftImgElement.attr("src", "/barndoor/images/sayles.jpg")

      sides = [ "left", "right" ]
      slides = [ @leftSlide, @rightSlide ]
      destinations = [ @leftDoorDestination, @rightDoorDestination ]
      for doorEl, i in [@leftDoors[@activeDoorIndex], @rightDoors[@activeDoorIndex]]
        suffix = "_" + sides[i] + "_" + @activeDoorIndex
        slide = slides[i]

        imgEl = $("#image" + suffix)
        titleEl = $("#title" + suffix)

        imgEl.attr("src", slide.imgUrl)
        titleEl.css("color", slide.fontColor)
        # TODO - should sanitize this input; maybe allow a couple of tags but not full blown control...
        titleEl.html(slide.title)

        if doAnimate
          doorEl.animate({
            "left": destinations[i] + "px",
          }, DefaultView.ANIMATION_LENGTH_MS, DefaultView.EASE_FXN)
        else
          doorEl.css("left", destinations[i] + "px")

  return DefaultView
)
