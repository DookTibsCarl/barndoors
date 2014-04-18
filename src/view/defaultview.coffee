# different views can do things like slice and dice the image, handle animating, etc.
# right now this is doing an awful lot...
define(["jquery"], (jq) ->
  class DefaultView
    # currently hardcoded, and polygons are associated with the overall view
    # and not with individual items. If we allow different polys per pair, 
    # need to rethink this...
    @TOP_EDGE_INSET = 50
    @BOTTOM_EDGE_INSET = 90

    @EASE_FXN = "swing"
    @ANIMATION_LENGTH_MS = 900

    constructor: (@targetDivName, @imgWidth, @imgHeight) ->
      console.log "building default view..."
      @targetDiv = $("##{@targetDivName}")

      this.createClippingPolygons()
      this.calculateCenteredSlidePositions()

      # console.log "left poly [#{@leftPoly}]"
      # foo = this.translatePointsFromArrayToString(@leftPoly);
      # console.log "strin rep [#{foo}]"

      targetDivStyling =
        "background-color": "gray",
        "overflow": "hidden",
        "position": "absolute"
      @targetDiv.css targetDivStyling

      @leftDoorElement = $("<div/>").attr("id", "doorLeft").appendTo(@targetDiv)
      @rightDoorElement = $("<div/>").attr("id", "doorRight").appendTo(@targetDiv)

      vertPos = (@targetDiv.height()/2) - (@imgHeight/2)
      console.log "vertPos is #{vertPos}"

      # debugAdjuster = 200
      debugAdjuster = 0

      @leftDoorElement.css(
        "position": "inherit",
        "left": ((-1 * @imgWidth) + debugAdjuster) + "px",
        "top": vertPos + "px"
      )

      @rightDoorElement.css(
        "position": "inherit",
        "left": (@targetDiv.width() - debugAdjuster) + "px",
        "top": vertPos + "px"
      )

      @leftImgElement = $("<img/>").attr("id", "imageLeft").appendTo(@leftDoorElement)
      @rightImgElement = $("<img/>").attr("id", "imageRight").appendTo(@rightDoorElement)

      # only necessary to clip the image element once; src can change later
      this.clipImage(@leftPoly, @leftImgElement)
      this.clipImage(@rightPoly, @rightImgElement)

      @leftLabelElement = $("<span/>").attr("id", "labelLeft").appendTo(@leftDoorElement)
      @rightLabelElement = $("<span/>").attr("id", "labelRight").appendTo(@rightDoorElement)

      @leftLabelElement.css(
        "position": "absolute"
        "right": "110px"
        "bottom": "20px"
        "letter-spacing": "-1px"
        "font": "bold 24px/8px Helvetica, Sans-Serif"
      )

      @rightLabelElement.css(
        "position": "absolute"
        "left": "110px"
        "bottom": "20px"
        "letter-spacing": "-1px"
        "font": "bold 24px/8px Helvetica, Sans-Serif"
      )

    clipImage: (points, imgToClip) ->
      if (imgToClip.length > 0)
        path = this.translatePointsFromArrayToString(points)
        console.log "clipped [#{imgToClip}] with [#{path}]"
        imgToClip.css(
          "-webkit-clip-path": path
        )

    # this and createClippingPolygons (maybe clipImage to) 
    # really should be broken out into some kind of utility class
    translatePointsFromArrayToString: (points) ->
      rv = "polygon("
      for p, i in points
        [x, y] = p
        rv += (if i == 0 then "" else ", ") + x + "px " + y + "px"
      rv += ")"
      rv

    createClippingPolygons: ->
      @leftPoly = [
        [0, 0],
        [@imgWidth - DefaultView.TOP_EDGE_INSET, 0],
        [@imgWidth - DefaultView.BOTTOM_EDGE_INSET, @imgHeight],
        [0, @imgHeight],
      ]

      @rightPoly = [
        [DefaultView.BOTTOM_EDGE_INSET, 0],
        [@imgWidth, 0],
        [@imgWidth, @imgHeight],
        [DefaultView.TOP_EDGE_INSET, @imgHeight],
      ]

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

    doSomethingCool: ->
      # this.centerSlides(true)

    centerSlides: (doAnimate = true) ->
      console.log "do something neat"
      # @leftImgElement.attr("src", "/barndoor/images/sayles.jpg")

      @leftImgElement.attr("src", @leftSlide.imgUrl)
      @rightImgElement.attr("src", @rightSlide.imgUrl)

      @leftLabelElement.css("color", @leftSlide.fontColor)
      @rightLabelElement.css("color", @rightSlide.fontColor)

      @leftLabelElement.text(@leftSlide.label)
      @rightLabelElement.text(@rightSlide.label)

      if (doAnimate)
        @leftDoorElement.animate({
          "left": @leftDoorDestination + "px",
        }, @ANIMATION_LENGTH_MS, @EASE_FXN)

        @rightDoorElement.animate({
          "left": @rightDoorDestination + "px",
        }, @ANIMATION_LENGTH_MS, @EASE_FXN)
      else
        @leftDoorElement.css("left", @leftDoorDestination + "px")
        @rightDoorElement.css("left", @rightDoorDestination + "px")
        

  return DefaultView
)
