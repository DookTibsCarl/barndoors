define([], () ->
  class AbstractView
    # points is an array of arrays. Each sub-array is x in slot 0, y in slot 1. imgToClip is a jquery image element
    clipImage: (points, imgToClip) ->
      if (imgToClip.length > 0)
        path = this.translatePointsFromArrayToString(points)
        imgToClip.css(
          "-webkit-clip-path": path
        )

    # translates from array-of-arrays points representation to the "polygon()" style svg notation
    translatePointsFromArrayToString: (points) ->
      rv = "polygon("
      for p, i in points
        [x, y] = p
        rv += (if i == 0 then "" else ", ") + x + "px " + y + "px"
      rv += ")"
      rv

    createClippingPolygons: (imgWidth, imgHeight, topEdgeInset, bottomEdgeInset) ->
      leftPoly = [
        [0, 0],
        [imgWidth - topEdgeInset, 0],
        [imgWidth - bottomEdgeInset, imgHeight],
        [0, imgHeight],
      ]

      rightPoly = [
        [bottomEdgeInset, 0],
        [imgWidth, 0],
        [imgWidth, imgHeight],
        [topEdgeInset, imgHeight],
      ]

      [leftPoly, rightPoly]

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
