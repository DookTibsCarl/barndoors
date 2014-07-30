define(["view/animatedview"], (AnimatedView) ->
  class FullTextBelowAnimatedView extends AnimatedView
    FOLD_PROPORTION = .05 # how much of the "middle" of the images should get folder "under"?
    PAD_PROPORTION = .03  # how much padding do you want on the textfields?

    @DESC_FONT_SCALE_DATA = { ratio: 25, min: 14, max: 999 }

    constructor: (@mainController, @targetDivName, @imageAspectRatio) ->
      super(@mainController, @targetDivName, @imageAspectRatio)
      @requiredDetailVerticalSpace = -1

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
      console.log("enforcing aspect ratio on [" + @targetDiv.attr('id') + "]")
      parentDivWidth = @targetDiv.parent().width()
      if (parentDivWidth % 2 == 1) then @targetDiv.width(parentDivWidth + 1) else @targetDiv.width(parentDivWidth)
      @mainController.debugWrapperWidths()

      adjustedHeight = @targetDiv.width()/2
      @maxDesiredImageHeight = adjustedHeight

      # new approach - just set the height to this basic aspect. We'll add room for the details in later, after we've been able to calculate required text height
      @targetDiv.height(adjustedHeight)
      @requiredDetailVerticalSpace = -1

      ###
      # now add some space to hold the description/details text
      # for instance, if old percent was .25. In diagonal mode, we'd see 1/4 of the avilable 
      adjustmentFactor = AnimatedView.TEXT_SHADOWBOX_PERCENT / (1 - AnimatedView.TEXT_SHADOWBOX_PERCENT)
      adjustedHeight += adjustedHeight * adjustmentFactor

      @targetDiv.height(adjustedHeight)

      @logToConsole("aspect restricted window to [" + @targetDiv.width() + "]x[" + @targetDiv.height() + "]")
      ###

    buildOutDoor: (doorEl, letter, letterLooper, side, otherSide, elementSuffix) ->
      doorStyle = {
        position: "inherit",
        display: (if letterLooper == 0 then "block" else "none")
        height: "100%"
        overflow: "hidden"
        # "background-color": "purple"
        "border-style": "solid"
        "border-width": "1px"
        "border-color": "white"
      }

      detailsStyle = {
        position: "absolute"
        # letterSpacing: "1px",
        # font: "12px/12px Arial",
        # color: "white"
        # "background-color": "purple"
        height: "100%"
        "text-align": otherSide
      }

      titleStyle = {
        position: "absolute"
        # letterSpacing: "1px"
        # color: "white"
        # font: "bold 30px/30px Helvetica, Sans-Serif"
        "text-align": otherSide
        "line-height": "90%"
      }

      $("<img/>").attr({ id: "image" + elementSuffix }).css({ position: "absolute" }).appendTo(doorEl)

      # use border-box to keep things reasonable
      for style in [ doorStyle, detailsStyle, titleStyle ]
        for sanity in [ "", "-moz-", "-webkit-" ]
          style[sanity + "box-sizing"] = "border-box"

      doorEl.css(doorStyle)

      titleEl = $("<div/>").attr("id", "title" + elementSuffix).css(titleStyle).addClass("title").appendTo(doorEl)
      detailsEl = $("<div/>").attr("id", "details" + elementSuffix).css(detailsStyle).addClass("details").appendTo(doorEl)
      # @putDoorInOpenPosition(doorEl, side)

    updateDoorElementsForCurrentDimensions: (side, elementSuffix) ->
      # adjust the door
      $("#door" + elementSuffix).css({ width: @halfDiv })

      # adjust the image
      if (side == AnimatedView.SIDE_LEFT)
        # imgPos = (@dynamicImageWidth - @halfDiv) * -1
        # imgPos += @foldAmount
        imgPos = 0
      else
        imgPos = 0
        imgPos -= @foldAmount

      # max-width is not needed in standalone dev environment, but on the reason page I developed against, there was a "img { max-width=100% }" css rule
      # that was causing issues
      $("#image" + elementSuffix).width(@dynamicImageWidth).height(@dynamicImageHeight).css({left: imgPos, "max-width": @targetDiv.width()})

      # adjust the text
      detailStyleUpdate = {
        # padding: @textPadAmount
        "padding-left": @textPadAmount
        "padding-right": @textPadAmount
        top: @dynamicImageHeight
        width: @halfDiv
        # height: @slideContainerDiv.height() - @maxDesiredImageHeight
        "font-size": @figureScaledFontSize(FullTextBelowAnimatedView.DESC_FONT_SCALE_DATA, @dynamicImageHeight)
      }

      titleStyleUpdate = {
        padding: @textPadAmount
        # bottom: @targetDiv.height() - @dynamicImageHeight
        width: @halfDiv
        "font-size": @figureScaledFontSize(FullTextBelowAnimatedView.TITLE_FONT_SCALE_DATA, @dynamicImageHeight)
      }

      $("#title" + elementSuffix).css(titleStyleUpdate)
      $("#details" + elementSuffix).css(detailStyleUpdate)

      # CALCULATE THE rEQUIRED HEIGHT OF THE DETAILS TEXT - START
      if (@requiredDetailVerticalSpace == -1)
        console.log("!!!!! recalculating required detail vertical space!")
        @requiredDetailVerticalSpace = @smartFontUpdate()

        # update - if we leave top/bottom padding on, it screws up the height
        # calculations in smartFontUpdate. Workaround: smartFontUpdate now 
        # sets those to zero and calculates the required height. We then re-add
        # the padding to the top and bottom, and bump the requiredDetailVerticalSpace
        # variable to match.
        @requiredDetailVerticalSpace += Math.ceil(@textPadAmount * 2)

        @slideContainerDiv.height(@maxDesiredImageHeight + @requiredDetailVerticalSpace)

        # we need to update the height/bottom coords of the details/title text after recalculating the required vertical space...
        for letter, i in ["A","B"]
          for side in AnimatedView.SIDES
            elementSuffix = "_#{side}_#{i}"
            $("#details" + elementSuffix).css({"height": @requiredDetailVerticalSpace, "padding-bottom": @textPadAmount, "padding-top": @textPadAmount})
            $("#title" + elementSuffix).css("bottom", @requiredDetailVerticalSpace)
            # $("#details" + elementSuffix).css("height", "auto")

        @targetDiv.height(@maxDesiredImageHeight + @requiredDetailVerticalSpace)
        # console.log("AFTER [" + @targetDiv.height() + "]")
      # CALCULATE THE rEQUIRED HEIGHT OF THE DETAILS TEXT - END

    checkFontHeights: () ->
      leftDoor = @leftDoors[@activeDoorIndex]
      rightDoor = @rightDoors[@activeDoorIndex]
      for d, i in [leftDoor, rightDoor]
        console.log("CHECKING FONT ON [" + (if i == 0 then "left" else "right") + "] SIDE!")
        details = d.children(".details")
        console.log("details is actually [" + details.height() + "] pixels tall")

    smartFontUpdate: () ->
      if not @allDetailText
        return 0

      # upsize stuff to 
      @slideContainerDiv.height(@slideContainerDiv.height()*2)
      @targetDiv.height(@targetDiv.height()*2)

      tester = $("#details_left_0")
      savedCopy = tester.html()
      tester.css({"height": "auto", "padding-top": "", "padding-bottom": ""})
      maxHeight = 0
      for desc, i in @allDetailText
        # console.log("[" + i + "] -> [" + desc + "]")
        tester.html(desc)
        console.log("height now [" + tester.height() + "]")
        maxHeight = Math.max(maxHeight, tester.height())

      maxHeight = Math.ceil(maxHeight)

      # console.log("found max height [" + maxHeight + "]")

      # can't figure out one bug - occasionally a line appears too low.
      # never mind - turned off vertical padding and that seems to have adjusted things well
      # maxHeight += Math.ceil((.35 * @figureScaledFontSize(FullTextBelowAnimatedView.DESC_FONT_SCALE_DATA, @dynamicImageHeight, false)))

      tester.html(savedCopy)

      return maxHeight




  return FullTextBelowAnimatedView
)
