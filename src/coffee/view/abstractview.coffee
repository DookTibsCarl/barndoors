# at this point not really an abstract view; more of a general utility class. Plan is to flesh this out tho.
define([], () ->
  class AbstractView

    logToConsole: (s) ->
      console.log(this.constructor.name + "::" + s)

    renderInitialView: (pair) ->
      @logToConsole "renderInitialView not implemented for [" + this.constructor.name + "]"

    togglePlayPause: (index) ->
      $.event.trigger({
        type: "toggleAutoplaySlideshow"
      })

    jumpToIndex: (index) ->
      $.event.trigger({
        type: "jumpToSlideIndex"
        jumpIndex: index
      })

    moveToNextIndex: () ->
      $.event.trigger({
        type: "moveToNextSlideIndex"
      })

    moveToPrevIndex: () ->
      $.event.trigger({
        type: "moveToPrevSlideIndex"
      })

    showNextPair: (index, pair, reversing = false) ->
      @logToConsole "showNextPair not implemented for [" + this.constructor.name + "]"

    updatePlayPauseStatus: (isPlaying) ->
      @logToConsole "updatePlayPauseStatus not implemented for [" + this.constructor.name + "]"

    pseudoDestructor: () ->
      @logToConsole "pseudoDestructor::[" + this.constructor.name + "]"

    # see http://sawyerhollenshead.com/writing/using-svg-clippath/
    
    # points is an array of arrays. Each sub-array is x in slot 0, y in slot 1. imgToClip is a jquery image element
    # currently works in Firefox, Safari, Chrome on OSX. IE? Mobile?
    clipElement: (points, imgToClip, svgUrlId) ->
      @logToConsole "CLIP ELEMENT DELAYED!!!!!"
      return

      if (imgToClip.length > 0)
        path = this.translatePointsFromArrayToWebkitString(points)
        imgToClip.css("clip-path", "url('##{svgUrlId}')")
        imgToClip.css("-webkit-clip-path", path)

    # translates from array-of-arrays points representation to the "polygon()" style svg notation
    translatePointsFromArrayToWebkitString: (points) ->
      rv = "polygon("
      for p, i in points
        [x, y] = p
        rv += (if i == 0 then "" else ", ") + x + "px " + y + "px"
      rv += ")"
      rv

    translatePointsFromArrayToSVGNotation: (points) ->
      rv = ""
      for p, i in points
        [x, y] = p
        rv += (if i == 0 then "" else ",") + x + " " + y
      rv

    DEG_TO_RAD = Math.PI/180
    RAD_TO_DEG = 180/Math.PI

    # takes a 5 point polygon (upper left, upper right, lower right, lower left, back to upper left) and shifts it by some adjustment
    squeezePoly: (p, topAdjust, bottomAdjust, leftAdjust, rightAdjust) ->
      if (p.length != 5)
        return p
      topLeft = p[0]
      topRight = p[1]
      bottomRight = p[2]
      bottomLeft = p[3]
      topLeftLoop = p[4]

      [ topLeft[0], topLeft[1] ] = [ topLeft[0] + leftAdjust, topLeft[1] + topAdjust ]
      [ topRight[0], topRight[1] ] = [ topRight[0] + rightAdjust, topRight[1] + topAdjust ]
      [ bottomRight[0], bottomRight[1] ] = [ bottomRight[0] + rightAdjust, bottomRight[1] + bottomAdjust ]
      [ bottomLeft[0], bottomLeft[1] ] = [ bottomLeft[0] + leftAdjust, bottomLeft[1] + bottomAdjust ]
      [ topLeftLoop[0], topLeftLoop[1] ] = [ topLeftLoop[0] + leftAdjust, topLeftLoop[1] + topAdjust ]

      return [topLeft, topRight, bottomRight, bottomLeft, topLeftLoop]
      

    createClippingPolygons: (imgWidth, imgHeight, topEdgeInset, bottomEdgeInset, textBoxHeight) ->
      leftImagePoly = [
        [0, 0],
        [imgWidth - topEdgeInset, 0],
        [imgWidth - bottomEdgeInset, imgHeight],
        [0, imgHeight],
        [0, 0]
      ]

      rightImagePoly = [
        [bottomEdgeInset, 0],
        [imgWidth, 0],
        [imgWidth, imgHeight],
        [topEdgeInset, imgHeight],
        [bottomEdgeInset, 0],
      ]

      # do a little trig to calculate the angle of the relevant triangle; we'll need this to properly crop the background text box
      # fullHypotenuseLength = Math.sqrt((imgHeight * imgHeight) + (insetDiff * insetDiff))
      # @logToConsole "triangle width=[" + insetDiff + "], triangle height=[" + imgHeight + "], fullHypotenuseLength = [" + fullHypotenuseLength + "]"
      insetDiff = Math.abs(topEdgeInset - bottomEdgeInset)
      bottomAngle = Math.atan(imgHeight / insetDiff) * RAD_TO_DEG
      topAngle = Math.atan(insetDiff / imgHeight) * RAD_TO_DEG
      @logToConsole "angles are [" + bottomAngle + "] / [" + topAngle + "]"

      textTriangleBase = textBoxHeight / Math.tan(bottomAngle * DEG_TO_RAD)

      leftTextPoly = [
        [0, 0],
        [imgWidth - bottomEdgeInset + textTriangleBase, 0],
        [imgWidth - bottomEdgeInset, textBoxHeight],
        [0, textBoxHeight]
      ]

      rightTextPoly = [
        [topEdgeInset + textTriangleBase, 0],
        [imgWidth, 0],
        [imgWidth, textBoxHeight],
        [topEdgeInset, textBoxHeight]
      ]

      [leftImagePoly, rightImagePoly, leftTextPoly, rightTextPoly]

    # elements are jquery elements. elementA will be given a higher z-order than B, swapping if necssary
    stackElements: (elementA, elementB) ->
      # zIndex was throwing errors; css property contained "auto". Just set it manually.
      zA = 2#elementA.zIndex()
      zB = 1#elementB.zIndex()

      topIdx = Math.max(zA, zB)
      bottomIdx = Math.min(zA, zB)

      if topIdx == bottomIdx
        topIdx++

      # elementA.zIndex(topIdx)
      # elementB.zIndex(bottomIdx)
      elementA.css("z-index", topIdx)
      elementB.css("z-index", bottomIdx)


    # pinched from http://stackoverflow.com/questions/1720320/how-to-dynamically-create-css-class-in-javascript-and-apply and rewritten in CS
    ###
    createCSSSelector: (selector, style) ->
      if (!document.styleSheets)
        return

      if (document.getElementsByTagName("head").length == 0)
        return

      if (document.styleSheets.length > 0)
        for ss, i in document.styleSheets
          if (ss.disabled)
            continue

          media = ss.media
          mediaType = typeof media

          if (mediaType == "string")
            if (media == "" or (media.indexOf("screen") != -1))
              styleSheet = ss
          else if (mediaType == "object")
            if (media.mediaText == "" or (media.mediaText.indexOf("screen") != -1))
              styleSheet = ss

          if (typeof styleSheet != "undefined")
            break

      if (typeof styleSheet == "undefined")
        styleSheetElement = document.createElement("style")
        styleSheetElement.type = "text/css"

        document.getElementsByTagName("head")[0].appendChild(styleSheetElement)

        for ss, i in document.styleSheets
          if ss.disabled
            continue
          styleSheet = ss

        media = styleSheet.media
        mediaType = typeof media

      if (mediaType == "string")
        for rule, i in styleSheet.rules
          if (rule.selectorText and rule.selectorText.toLowerCase() == selector.toLowerCase())
            rule.style.cssText = style
            return

        styleSheet.addRule(selector, style)
      else if (mediaType == "object")
        for rule, i in styleSheet.cssRules
          if (rule.selectorText and rule.selectorText.toLowerCase() == selector.toLowerCase())
            rule.style.cssText = style
            return

        styleSheet.insertRule(selector + "{" + style + "}", styleSheet.cssRules.length)
    ###

  return AbstractView
)
