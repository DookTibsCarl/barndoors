# at this point not really an abstract view; more of a general utility class. Plan is to flesh this out tho.
define([], () ->
  class AbstractView

    # see http://sawyerhollenshead.com/writing/using-svg-clippath/
    
    # points is an array of arrays. Each sub-array is x in slot 0, y in slot 1. imgToClip is a jquery image element
    clipElement: (points, imgToClip, svgUrlId) ->
      if (imgToClip.length > 0)
        console.log "really clipping [" + imgToClip.attr('id') + "]/[" + svgUrlId + "]..."
        path = this.translatePointsFromArrayToWebkitString(points)
        ###
        imgToClip.css(
          "clip-path": "url('##{svgUrlId}')",
          "-webkit-clip-path": path,
        )
        ###

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

    createClippingPolygons: (imgWidth, imgHeight, topEdgeInset, bottomEdgeInset, textBoxHeight) ->
      leftImagePoly = [
        [0, 0],
        [imgWidth - topEdgeInset, 0],
        [imgWidth - bottomEdgeInset, imgHeight],
        [0, imgHeight],
      ]

      rightImagePoly = [
        [bottomEdgeInset, 0],
        [imgWidth, 0],
        [imgWidth, imgHeight],
        [topEdgeInset, imgHeight],
      ]

      # do a little trig to calculate the angle of the relevant triangle; we'll need this to properly crop the background text box
      # fullHypotenuseLength = Math.sqrt((imgHeight * imgHeight) + (insetDiff * insetDiff))
      # console.log "triangle width=[" + insetDiff + "], triangle height=[" + imgHeight + "], fullHypotenuseLength = [" + fullHypotenuseLength + "]"
      insetDiff = Math.abs(topEdgeInset - bottomEdgeInset)
      bottomAngle = Math.atan(imgHeight / insetDiff) * RAD_TO_DEG
      topAngle = Math.atan(insetDiff / imgHeight) * RAD_TO_DEG
      console.log "angles are [" + bottomAngle + "] / [" + topAngle + "]"

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

  return AbstractView
)
