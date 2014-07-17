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

      @foldAmount = @halfDiv * FOLD_PROPORTION
      @textPadAmount = @halfDiv * PAD_PROPORTION


      # now calculate open/closed positions
      centerOfDiv = @slideContainerDiv.width() / 2
      @leftDoorClosedDestination = 0
      @rightDoorClosedDestination = centerOfDiv
      @leftDoorOpenDestination = -1 * @halfDiv
      @rightDoorOpenDestination = @slideContainerDiv.width()

    enforceAspectRatio: () ->
      adjustedHeight = @targetDiv.width()/2
      @maxDesiredImageHeight = adjustedHeight

      # now add some space to hold the description/details text
      # for instance, if old percent was .25. In diagonal mode, we'd see 1/4 of the avilable 
      adjustmentFactor = AnimatedView.TEXT_SHADOWBOX_PERCENT / (1 - AnimatedView.TEXT_SHADOWBOX_PERCENT)
      adjustedHeight += adjustedHeight * adjustmentFactor

      @targetDiv.height(adjustedHeight)

    buildOutDoor: (doorEl, letter, letterLooper, side, otherSide, elementSuffix) ->
      doorStyle = {
        position: "inherit",
        display: (if letterLooper == 0 then "block" else "none")
        height: "100%"
        overflow: "hidden"
        "border-style": "solid"
        "border-width": "1px"
        "border-color": "white"
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

      # use border-box to keep things reasonable
      for style in [ doorStyle, detailsStyle, titleStyle ]
        for sanity in [ "", "-moz-", "-webkit-" ]
          style[sanity + "box-sizing"] = "border-box"

      doorEl.css(doorStyle)

      titleEl = $("<div/>").attr("id", "title" + elementSuffix).css(titleStyle).appendTo(doorEl)
      detailsEl = $("<div/>").attr("id", "details" + elementSuffix).css(detailsStyle).appendTo(doorEl)
      # @putDoorInOpenPosition(doorEl, side)

    updateDoorElementsForCurrentDimensions: (side, elementSuffix) ->
      # adjust the door
      $("#door" + elementSuffix).css({ width: @halfDiv })

      # adjust the image
      imgEl = document.getElementById("image" + elementSuffix)
      imgEl.width = @dynamicImageWidth
      imgEl.height = @dynamicImageHeight

      if (side == AnimatedView.SIDE_LEFT)
        imgPos = (@dynamicImageWidth - @halfDiv) * -1
        imgPos += @foldAmount
      else
        imgPos = 0
        imgPos -= @foldAmount
      imgEl.style.left = imgPos + "px"

      # adjust the text
      detailStyleUpdate = {
        padding: @textPadAmount
        top: @dynamicImageHeight
        width: @halfDiv
      }

      titleStyleUpdate = {
        padding: @textPadAmount
        bottom: @targetDiv.height() - @dynamicImageHeight
        width: @halfDiv
      }

      $("#title" + elementSuffix).css(titleStyleUpdate)
      $("#details" + elementSuffix).css(detailStyleUpdate)

  return FullTextBelowAnimatedView
)
