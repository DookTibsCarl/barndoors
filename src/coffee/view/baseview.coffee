# the parent class that ALL views should inherit from. Think of it as pseudo-abstract; it certainly should not
# be instantiated and used as-is.

define([], () ->
  class BaseView
    @SVG_NS = "http://www.w3.org/2000/svg"
    @XLINK_NS = "http://www.w3.org/1999/xlink"

    @SIDE_LEFT = "left"
    @SIDE_RIGHT = "right"
    @SIDES = [ @SIDE_LEFT, @SIDE_RIGHT ]

    # how many pixels of div height do we want for each pixel of font height? Larger numbers for ratio means a smaller font. Min/max set bounds. Subclasses can override these.
    @TITLE_FONT_SCALE_DATA = { ratio: 10, min: 20, max: 999 }
    @DESC_FONT_SCALE_DATA = { ratio: 35, min: 10, max: 999 }

    # set these to zero to disable
    @TITLE_DISTANCE_FROM_BLACKBAR_PADDING_RATIO = .2 # when positioning "title" text,shift it up this value * actual height of the black bar
    @DETAILS_DISTANCE_FROM_BLACKBAR_PADDING_RATIO = .22 # when positioning "details" text,shift it down this value * actual height of the black bar



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

    responsiveUpdate: () ->
      @logToConsole "responsiveUpdate not implemented for [" + this.constructor.name + "]"

    updatePlayPauseStatus: (isPlaying) ->
      @logToConsole "updatePlayPauseStatus not implemented for [" + this.constructor.name + "]"

    pseudoDestructor: () ->
      @logToConsole "pseudoDestructor::[" + this.constructor.name + "]"

    translatePointsFromArrayToSVGNotation: (points) ->
      rv = ""
      for p, i in points
        [x, y] = p
        rv += (if i == 0 then "" else ",") + x + " " + y
      rv

    figureScaledFontSize: (scaleData, comparisonHeight) ->
      rv = comparisonHeight / scaleData.ratio
      rv = Math.max(rv, scaleData.min)
      rv = Math.min(rv, scaleData.max)
      return rv + "px"


    # takes a 5 point polygon (upper left, upper right, lower right, lower left, back to upper left) and shifts it by some adjustment
    squeezePoly: (p, topAdjust, bottomAdjust, leftAdjust, rightAdjust) ->
      if (p.length != 5)
        return p
      topLeft = p[0]
      topRight = p[1]
      bottomRight = p[2]
      bottomLeft = p[3]
      topLeftLoop = p[4]

      topLeftCopy = []; topRightCopy = []; bottomRightCopy = []; bottomLeftCopy = []; topLeftLoopCopy = [];
      [ topLeftCopy[0], topLeftCopy[1] ] = [ topLeft[0] + leftAdjust, topLeft[1] + topAdjust ]
      [ topRightCopy[0], topRightCopy[1] ] = [ topRight[0] + rightAdjust, topRight[1] + topAdjust ]
      [ bottomRightCopy[0], bottomRightCopy[1] ] = [ bottomRight[0] + rightAdjust, bottomRight[1] + bottomAdjust ]
      [ bottomLeftCopy[0], bottomLeftCopy[1] ] = [ bottomLeft[0] + leftAdjust, bottomLeft[1] + bottomAdjust ]
      [ topLeftLoopCopy[0], topLeftLoopCopy[1] ] = [ topLeftLoop[0] + leftAdjust, topLeftLoop[1] + topAdjust ]

      rv = [topLeftCopy, topRightCopy, bottomRightCopy, bottomLeftCopy, topLeftLoopCopy]
      return rv

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

    addElement: (elementType, elementId, attribs, container) ->
      el = document.createElement(elementType)
      if (elementId != "" and elementId != null)
        el.id = elementId
      if (attribs != null)
        @addAttributeHelper(el, attribs)
      container.appendChild(el)
      return el
      
      
    # helper function to simplify creating namespace elements (currently used for building out the svg structures)
    addNSElement: (elementType, elementId, attribs, container, namespace = BaseView.SVG_NS) ->
      el = document.createElementNS(namespace, elementType)
      if (elementId != "" and elementId != null)
        el.id = elementId
      if (attribs != null)
        @addAttributeHelper(el, attribs)
      container.appendChild(el)
      return el

    updateNSElement: (elementId, attribs) ->
      el = document.getElementById(elementId)
      if (el != null)
        @addAttributeHelper(el, attribs)
      
    addAttributeHelper: (o, attribs) ->
      for n, v of attribs
        o.setAttribute(n, v)

    # see https://developer.mozilla.org/en-US/docs/Browser_detection_using_the_user_agent
    getUserAgentData: () ->
      ua = navigator.userAgent
      # get browser...
      if (ua.indexOf("Firefox/") != -1 and ua.indexOf("Seamonkey/") == -1)
        browserName = "Firefox"
      else if (ua.indexOf("Seamonkey/") != -1)
        browserName = "Seamonkey"
      else if (ua.indexOf("Safari/") != -1 and (ua.indexOf("Chrome/") == -1 and ua.indexOf("Chromium/") == -1))
        browserName = "Safari"
      else if (ua.indexOf("Chrome/") != -1 and ua.indexOf("Chromium/") == -1)
        browserName = "Chrome"
      else if (ua.indexOf("Chromium/") != -1)
        browserName = "Chromium"
      else if (ua.indexOf("MSIE") != -1)
        browserName = "IE"
      else if (ua.indexOf("OPR/") != -1 or ua.indexOf("Opera/") != -1)
        browserName = "Opera"
      else
        browserName = "unknown"

      # get some kind of version we care about...
      if (browserName == "IE")
        re  = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})")
        if (re.exec(ua) != null)
          version = parseFloat( RegExp.$1 )
      else if (browserName == "Safari")
        re  = new RegExp("Version/([.0-9]+) Safari")
        if (re.exec(ua) != null)
          version = parseFloat( RegExp.$1 )
      else if (browserName == "Chrome")
        re  = new RegExp("Chrome/([.0-9]+) ")
        if (re.exec(ua) != null)
          version = parseFloat( RegExp.$1 )
      else
        version = -1

      # get rendering engine...
      if (ua.indexOf("Gecko/") != -1)
        renderingEngine = "Gecko"
      else if (ua.indexOf("AppleWebKit/") != -1)
        renderingEngine = "WebKit"
      else if (ua.indexOf("Opera/") != -1)
        renderingEngine = "Presto"
      else if (ua.indexOf("Trident/") != -1)
        renderingEngine = "Trident"
      else if (ua.indexOf("Chrome/") != -1)
        renderingEngine = "Blink"
      else
        renderingEngine = "unknown"

      # special case - builtin android browser
      isStockAndroid = ((ua.indexOf('Mozilla/5.0') > -1 and ua.indexOf('Android ') > -1 and ua.indexOf('AppleWebKit') > -1) and !(ua.indexOf('Chrome') > -1))

      $("#debugUserAgent").html("browser [" + browserName + "], version [" + version + "], renderingEngine [" + renderingEngine + "]<br>(" + ua + ")")
      return {
        name: browserName
        version: version
        renderingEngine: renderingEngine
        isStockAndroid: isStockAndroid
      }

  return BaseView
)
