define(["view/animatedview"], (AnimatedView) ->
  class FullTextBelowAnimatedView extends AnimatedView
    FOLD_PROPORTION = .12 # how much of the "middle" of the images should get folder "under"?
    PAD_PROPORTION = .03  # how much padding do you want on the textfields?

    constructor: (@mainController, @targetDivName, @imageAspectRatio) ->
      super(@mainController, @targetDivName, @imageAspectRatio)

    setupCalculations: () ->
      @halfDiv = @targetDiv.width()/2
      @dynamicImageHeight = @maxDesiredImageHeight
      @dynamicImageWidth = @dynamicImageHeight * @imageAspectRatio
      @imageUnderflow = @targetDiv.width() - @dynamicImageWidth
      @halfImgWidth = @dynamicImageWidth / 2

      # calculate the outlines
      ###
      @rightOutlinePoly = [
        [0, 0]
        [@halfDiv, 0]
        [@halfDiv, @targetDiv.height()]
        [0, @targetDiv.height()]
      ]
      @wrapUpPoly(@rightOutlinePoly)

      @leftOutlinePoly = @rightOutlinePoly
      ###

      # now calculate open/closed positions
      centerOfDiv = @slideContainerDiv.width() / 2
      @leftDoorClosedDestination = centerOfDiv - @targetDiv.width()
      @rightDoorClosedDestination = centerOfDiv
      @leftDoorOpenDestination = (-1 * @dynamicImageWidth) - @imageUnderflow
      @rightDoorOpenDestination = @slideContainerDiv.width()

    enforceAspectRatio: () ->
      adjustedHeight = @targetDiv.width()/2
      @maxDesiredImageHeight = adjustedHeight

      # for instance, if old percent was .25. In diagonal mode, we'd see 1/4 of the avilable 
      adjustmentFactor = AnimatedView.TEXT_SHADOWBOX_PERCENT / (1 - AnimatedView.TEXT_SHADOWBOX_PERCENT)
      adjustedHeight += adjustedHeight * adjustmentFactor

      @targetDiv.height(adjustedHeight)

    buildOutDoor: (doorEl, letter, letterLooper, side, otherSide, elementSuffix) ->
      doorStyle = {
        position: "inherit",
        display: (if letterLooper == 0 then "block" else "none")
        width: "100%"
        height: "100%"
        overflow: "hidden"

        # "border-style": "solid"
        # "border-width": "3px"
        # "border-color": "white"
      }

      detailsStyle = {
        position: "absolute"
        letterSpacing: "1px",
        font: "12px/12px Arial",
        color: "white"
        "background-color": "#7095B7"
        height: "100%"
        "text-align": otherSide
      }

      titleStyle = {
        position: "absolute"
        letterSpacing: "1px"
        color: "white"
        font: "bold 30px/30px Helvetica, Sans-Serif"
        "text-align": otherSide
      }

      $("<img/>").attr({ id: "image" + elementSuffix }).css({ position: "absolute" }).appendTo(doorEl)

      # if the browser supports it, let's draw an outline
      ###
      if (document.createElementNS)
        svgAttribs = {width:"100%", height:"100%",baseProfile:"full",version:"1.2"}
        svgEl = @addNSElement("svg", "mover" + elementSuffix, svgAttribs, doorEl[0])
        @addNSElement("polyline", "outliner" + elementSuffix, {style: "fill:none; stroke:white; stroke-width:3"}, svgEl)
      ###


      # use border-box to keep things reasonable
      for style in [ detailsStyle, titleStyle ]
        for sanity in [ "", "-moz-", "-webkit-" ]
          style[sanity + "box-sizing"] = "border-box"

      doorEl.css(doorStyle)

      titleEl = $("<div/>").attr("id", "title" + elementSuffix).css(titleStyle).appendTo(doorEl)
      detailsEl = $("<div/>").attr("id", "details" + elementSuffix).css(detailsStyle).appendTo(doorEl)
      # @putDoorInOpenPosition(doorEl, side)

    updateDoorElementsForCurrentDimensions: (side, elementSuffix) ->
      # adjust the image
      imgEl = document.getElementById("image" + elementSuffix)
      imgEl.width = @dynamicImageWidth
      imgEl.height = @dynamicImageHeight

      foldAmount = @halfDiv * FOLD_PROPORTION
      if (side == AnimatedView.SIDE_LEFT)
        imgPos = @targetDiv.width() - @dynamicImageWidth
        imgPos += foldAmount
      else
        imgPos = 0
        imgPos -= foldAmount

      imgEl.style.left = imgPos + "px"

      # adjust the outliner
      # polyPoints = if side == AnimatedView.SIDE_LEFT then @leftOutlinePoly else @rightOutlinePoly
      # @updateNSElement("outliner" + elementSuffix, {points:polyPoints})

      # adjust the text
      paddingAmount = @halfDiv * PAD_PROPORTION
      wordsX = if side == AnimatedView.SIDE_LEFT then @targetDiv.width() - @halfDiv else 0

      detailStyleUpdate = {
        padding: paddingAmount
        top: @dynamicImageHeight
        left: wordsX
        width: @halfDiv
      }

      titleStyleUpdate = {
        padding: paddingAmount
        bottom: @targetDiv.height() - @dynamicImageHeight
        left: wordsX
        width: @halfDiv
      }

      $("#title" + elementSuffix).css(titleStyleUpdate)
      $("#details" + elementSuffix).css(detailStyleUpdate)

  return FullTextBelowAnimatedView
)
