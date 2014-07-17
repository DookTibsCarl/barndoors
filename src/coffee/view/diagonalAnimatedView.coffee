define(["view/animatedview"], (AnimatedView) ->
  class DiagonalAnimatedView extends AnimatedView
    DEG_TO_RAD = Math.PI/180
    RAD_TO_DEG = 180/Math.PI

    constructor: (@mainController, @targetDivName, @imageAspectRatio) ->
      super(@mainController, @targetDivName, @imageAspectRatio)
      @enableSvgImageSwaps = true

    buildOutDoors: () ->
      # before we build out doors, we want to set up some clip path stuff...
      if (@renderMode == AnimatedView.RENDER_MODE_CLIP_PATH)
        for side, i in AnimatedView.SIDES
          polyPoints = @translatePointsFromArrayToSVGNotation(if side == AnimatedView.SIDE_LEFT then @leftImagePoly else @rightImagePoly)
          svgEl = @addNSElement("svg", "", {width:0, height:0}, @slideContainerDiv[0])
          defsEl = @addNSElement("defs", "", null, svgEl)
          clipPathEl = @addNSElement("clipPath", side + "_clip_path", null, defsEl)
          polygonEl = @addNSElement("polygon", "clippath_poly_" + side, null, clipPathEl)
      super

    updateSideElementsForCurrentDimensions: (side) ->
      polyPoints = @translatePointsFromArrayToSVGNotation(if side == AnimatedView.SIDE_LEFT then @leftImagePoly else @rightImagePoly)
      @updateNSElement("clippath_poly_" + side, {points:polyPoints}) # this is the one used in RENDER_MODE_CLIP_PATH

    updateDoorElementsForCurrentDimensions: (side, elementSuffix) ->
      if (@renderMode == AnimatedView.RENDER_MODE_BASIC)
        # "fold" the middle-facing edge under, to come close to the viewport we get from the diagonal look
        if (side == AnimatedView.SIDE_LEFT)
          imagePos = @targetDiv.width() - @dynamicImageWidth + @halfDiag
        else
          imagePos = -1 * @halfDiag
        $("#image" + elementSuffix).width(@dynamicImageWidth).height(@dynamicImageHeight).css({left: imagePos, "max-width": @targetDiv.width()})

        @styleTemplatedBlackBar(side, elementSuffix)
      else if (@renderMode == AnimatedView.RENDER_MODE_DEFAULT or @renderMode == AnimatedView.RENDER_MODE_CLIP_PATH)
        polyPoints = @translatePointsFromArrayToSVGNotation(if side == AnimatedView.SIDE_LEFT then @leftImagePoly else @rightImagePoly)
        bbPoints = @translatePointsFromArrayToSVGNotation(if side == AnimatedView.SIDE_LEFT then @leftTextPoly else @rightTextPoly)

        underflowStartPos = @halfImgUnderflow * (if side == AnimatedView.SIDE_LEFT then -1 else 1)
        updatedViewbox = underflowStartPos + " 0 " + @targetDiv.width() + " " + @targetDiv.height()

        @updateNSElement("alignmentWrapper" + elementSuffix, {viewBox:updatedViewbox})
        @updateNSElement("maskpoly" + elementSuffix, {points:polyPoints})
        @updateNSElement("blackbox" + elementSuffix, {points:bbPoints})
        @updateNSElement("outliner" + elementSuffix, {points:polyPoints})

      # update where the title/description go
      [wordsX, wordsWidth] = @calculateTextPositions(side)
      titleStyleUpdate = { left: wordsX, width:wordsWidth, bottom: @actualShadowboxHeight }
      detailStyleUpdate = { left: wordsX, width:wordsWidth, top: @targetDiv.height() - @actualShadowboxHeight }
      $("#title" + elementSuffix).css(titleStyleUpdate)
      $("#details" + elementSuffix).css(detailStyleUpdate)
      

    performPrecalculations: () ->
      # a number of dimensions/calculations are used in a number of places - let's just do them up front.
      @halfDiv = @targetDiv.width()/2

      @dynamicImageHeight = @targetDiv.height()
      @dynamicImageWidth = @dynamicImageHeight * @imageAspectRatio
      @imageUnderflow = @targetDiv.width() - @dynamicImageWidth

      if AnimatedView.DIAGONAL_ANGLE > 90
        amtAboveNinety = AnimatedView.DIAGONAL_ANGLE - 90
        @actualDiagonalInset = -1 * (@dynamicImageHeight / Math.tan((AnimatedView.DIAGONAL_ANGLE - (amtAboveNinety * 2)) * DEG_TO_RAD))
      else
        @actualDiagonalInset = @dynamicImageHeight / Math.tan(AnimatedView.DIAGONAL_ANGLE * DEG_TO_RAD)

      @halfDiag = @actualDiagonalInset / 2
      @halfImgUnderflow = @imageUnderflow / 2
      @halfImgWidth = @dynamicImageWidth / 2

      @actualShadowboxHeight = @targetDiv.height() * AnimatedView.TEXT_SHADOWBOX_PERCENT

    createClippingPolygons: () ->
      divWidth = @targetDiv.width()
      divHeight = @targetDiv.height()

      leftEdgeCoord = @halfImgUnderflow + (@dynamicImageWidth - @halfDiv - @halfDiag)
      rightEdgeCoord = @halfImgUnderflow + @halfDiag + @halfDiv

      @leftImagePoly = [
        [leftEdgeCoord, 0]
        [divWidth - (if @actualDiagonalInset > 0 then 0 else -1 * @actualDiagonalInset) - @halfImgUnderflow, 0]
        [divWidth - (if @actualDiagonalInset > 0 then @actualDiagonalInset else 0) - @halfImgUnderflow, divHeight]
        [leftEdgeCoord, divHeight]
      ]

      @rightImagePoly = [
        [@halfImgUnderflow + (if @actualDiagonalInset > 0 then @actualDiagonalInset else 0), 0]
        [rightEdgeCoord, 0]
        [rightEdgeCoord, divHeight]
        [@halfImgUnderflow + (if @actualDiagonalInset > 0 then 0 else -1 * @actualDiagonalInset), divHeight]
      ]

      # complete the polys - make a copy of the first point and clone it on the end
      # @leftImagePoly.push(@leftImagePoly[0])
      # @rightImagePoly.push(@rightImagePoly[0])
      @wrapUpPoly(@leftImagePoly)
      @wrapUpPoly(@rightImagePoly)

      topOfBox = @targetDiv.height() - @actualShadowboxHeight
      bottomOfBox = @targetDiv.height()

      angle = Math.atan(divHeight / @actualDiagonalInset) * RAD_TO_DEG
      triangleBase = @actualShadowboxHeight / Math.tan(angle * DEG_TO_RAD)

      diagAdjustment = (if @actualDiagonalInset > 0 then @actualDiagonalInset else 0)
      @leftTextPoly = [
        [leftEdgeCoord, topOfBox] 
        [divWidth - diagAdjustment - @halfImgUnderflow + triangleBase, topOfBox]
        [divWidth - diagAdjustment - @halfImgUnderflow, bottomOfBox]
        [leftEdgeCoord, bottomOfBox]
      ]

      @rightTextPoly = [
        [@halfImgUnderflow + triangleBase, topOfBox]
        [rightEdgeCoord, topOfBox]
        [rightEdgeCoord, bottomOfBox]
        [@halfImgUnderflow, bottomOfBox]
      ]

    calculateTextPositions: (side) ->
      if (@renderMode == AnimatedView.RENDER_MODE_BASIC)
        bumper = @halfDiv * .05 # gives us just a little padding around the words
        wordsWidth = @halfDiv - bumper*2
        if side == AnimatedView.SIDE_LEFT
          wordsX = @targetDiv.width() - wordsWidth - bumper
        else
          wordsX = bumper

      else
        wordsWidth = @halfDiv - Math.abs(@actualDiagonalInset)
        if side == AnimatedView.SIDE_LEFT
          wordsX = @imageUnderflow + @dynamicImageWidth - Math.abs(@actualDiagonalInset) - wordsWidth
        else
          wordsX = @actualDiagonalInset

      return [wordsX, wordsWidth]

    styleTemplatedBlackBar: (side, suffix) ->
      bbEl = document.getElementById("blackbox" + suffix)

      # the actual blackbar_template class can't know about the actual dimensions, so we need to update it now
      bbEl.style.top = @targetDiv.height() - @actualShadowboxHeight
      bbEl.style.height = @actualShadowboxHeight
      bbEl.style.left = if side == AnimatedView.SIDE_LEFT then @halfDiv else 0
      bbEl.style.width = @halfDiv

    # do some math to figure out what's the offscreen and centered positions for each side of the show
    calculateSlideDestinations: ->
      # set this to adjust how far onscreen (positive number) the starting position for a door should be
      # debugAdjuster = 200
      debugAdjuster = 0

      centerOfDiv = @slideContainerDiv.width() / 2

      # console.log("when calculating, slide container div is [" + @slideContainerDiv.width() + "]...image raw is [" + @imgWidth + "]...ACTUAL is [" + $(

      diagShifter = (@halfDiag * (if @actualDiagonalInset < 0 then -1 else 1))
      if (@renderMode == AnimatedView.RENDER_MODE_BASIC)
        @leftDoorClosedDestination = centerOfDiv - @targetDiv.width()
        @rightDoorClosedDestination = centerOfDiv
      else if (@renderMode == AnimatedView.RENDER_MODE_DEFAULT or @renderMode == AnimatedView.RENDER_MODE_CLIP_PATH)
        @leftDoorClosedDestination = 0 - @halfImgUnderflow - @halfImgWidth + diagShifter
        @rightDoorClosedDestination = centerOfDiv + (diagShifter * -1)

      # sometimes a gap is useful for debugging...
      gap = 0
      if gap > 0
        @leftDoorClosedDestination -= gap
        @rightDoorClosedDestination += gap

      # offscreen position is always the same
      @leftDoorOpenDestination = (-1 * @dynamicImageWidth) - @imageUnderflow + debugAdjuster
      @rightDoorOpenDestination = @slideContainerDiv.width() - debugAdjuster

    # BLAH - START

    setupCalculations: () ->
      # do some math setup
      @performPrecalculations()
      @createClippingPolygons()
      @calculateSlideDestinations()

    enforceAspectRatio: () ->
      @targetDiv.height(@targetDiv.width()/2)

    # as we go through here, some items will get stubbed out and not really fleshed out until we call updateDoorElementsForCurrentDimensions. This keeps
    # the logic for that in one place (it needs to be callable when doing a dynamic resize too) at the cost of a little bouncing around in the codebase...
    buildOutDoor: (doorEl, letter, letterLooper, side, otherSide, elementSuffix) ->
      @logToConsole "looping for [" + elementSuffix + "]"

      if (@renderMode == AnimatedView.RENDER_MODE_BASIC)
        # imgEl = @addElement("img", "image" + elementSuffix, {style: "position: absolute; left: " + imagePos + "px" }, doorEl[0])
        imgEl = @addElement("img", "image" + elementSuffix, {style: "position: absolute" }, doorEl[0])
        @addElement("div", "blackbox" + elementSuffix, {class: "blackbar_template"}, doorEl[0])

      else if (@renderMode == AnimatedView.RENDER_MODE_DEFAULT or @renderMode == AnimatedView.RENDER_MODE_CLIP_PATH)
        # now build out the svg stuff...this does NOT play nicely with JQuery so we just use plain JavaScript (with a helper fxn) to construct it all

        # NEED AN EXTRA SVG ELEMENT TO POSITION STUFF FLOATED TO LEFT/RIGHT
        svgAttribs = {width:"100%", height:"100%",baseProfile:"full",version:"1.2"}

        svgAttribs.preserveAspectRatio = "xMaxYMin meet"

        # underflow is how much smaller the image is than the containing div. Image is centered by default so we only need half. -1 to shift it right.
        underflowStartPos = @halfImgUnderflow * (if side == AnimatedView.SIDE_LEFT then -1 else 1)

        svgAttribs.viewBox = underflowStartPos + " 0 " + @targetDiv.width() + " " + @targetDiv.height()
        alignWrapEl = @addNSElement("svg", "alignmentWrapper" + elementSuffix, svgAttribs, doorEl[0])

        # next level down, svg
        svgAttribs = {width:"100%", height:"100%",baseProfile:"full",version:"1.2"}
        svgEl = @addNSElement("svg", "mover" + elementSuffix, svgAttribs, alignWrapEl)

        if (@renderMode == AnimatedView.RENDER_MODE_DEFAULT)
          svgImageAttribs = { mask: "url(#svgmask" + elementSuffix + ")" }

          # svgEl contains a "defs" element...
          defsEl = @addNSElement("defs", "", null, svgEl)

          # defs contains a mask...
          maskEl = @addNSElement("mask", "svgmask" + elementSuffix, {maskUnits:"userSpaceOnUse",maskContentUnits:"userSpaceOnUse",transform:"scale(1)"}, defsEl)

          # and mask contain a polygon
          polygonEl = @addNSElement("polygon", "maskpoly" + elementSuffix, {fill:"white"}, maskEl)

        else if (@renderMode == AnimatedView.RENDER_MODE_CLIP_PATH)
          svgImageAttribs = { "clip-path": "url(#" + side + "_clip_path)" }

        svgImageAttribs.width = "100%"
        svgImageAttribs.height = "100%"

        imgEl = @addNSElement("image", "image" + elementSuffix, svgImageAttribs, svgEl)

        # black box el is next
        bbEl = @addNSElement("polygon", "blackbox" + elementSuffix, {fill:"black", "fill-opacity": AnimatedView.TEXT_SHADOWBOX_OPACITY}, svgEl)

        # and now the border that appears around the edge of the slide
        @addNSElement("polyline", "outliner" + elementSuffix, {style: "fill:none; stroke:white; stroke-width:3"}, svgEl)
        # end of normal styling. CoffeeScript's lack of brackets is a little annoying sometimes

      this.putDoorInOpenPosition(doorEl, side)

      titleEl = $("<div/>").attr("id", "title" + elementSuffix).appendTo(doorEl)
      detailsEl = $("<div/>").attr("id", "details" + elementSuffix).appendTo(doorEl)

      # style things appropriately

      titleStyle = {
        position: "absolute"
        letterSpacing: "1px"
        color: "white"
        font: "bold 30px/30px Helvetica, Sans-Serif"
        "text-align": otherSide
      }

      detailsStyle = {
        position: "absolute"
        letterSpacing: "1px",
        font: "12px/12px Arial",
        color: "white"
        "text-align": otherSide
      }

      doorStyle = {
        position: "inherit",
        display: (if letterLooper == 0 then "block" else "none")
        width: "100%"
        height: "100%"
        overflow: "hidden"
      }

      doorEl.css(doorStyle)
      titleEl.css(titleStyle)
      detailsEl.css(detailsStyle)


  return DiagonalAnimatedView
)
