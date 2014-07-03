###

this class is responsible for handling image preloads. The individual views are set up to expect that when they are
told to display something, it's ok to display it - any preloading has already been done.

Basic outline - the client (the main app controller in this case) calls "ensureImagesLoaded" with a list of urls
and optionally a callback. ImageLoader checks to see if we already loaded these images, or if we are in the process
of loading them already. If necessary, it will start loading them in the background with some JQuery help. It will also
keep track of the callback if there was one, and this is associated with all the urls in the request

When a preload completes, we find the url in question and see if there were other urls and a callback associated with it.
For the initial load or when a user clicks on a specific slide, this is the case. If we are fetching the next slide to 
be ready, there will be no callback. Note that much of the complexity in this class results from this design choice - it needs
to handle situations like we started a preload for some images and then the user did something to either duplicate that request,
or nullify it.

End result - controller should treat this as a black box. It can always call "ensureImagesLoaded" and rely on the callback, if any,
being called appropriately. Likewise individual views don't need to concern themselves with preloading. They can assume that 
when the controller calls their "renderInitialView" or "showNextPair" methods that it's ok to show things.

###

define([""], () ->
  class ImageLoader
    @DISABLE_PRELOADS = false # used for testing only, NEVER SET THIS TO TRUE

    constructor: () ->
      @logToConsole "constructing ImageLoader..."
      @loadedImages = {}    # storage for images that we have successfully preloaded
      @activeLoaders = {}   # storage for offscreen <img> elements that we are using to handle preloads
      @postLoadRouters = [] # each element of the array is an object with two properties: 1. "urls": an array of image urls.
                            #                                                             2. "callback": a function to call once all "urls" are loaded

    logToConsole: (s) ->
      console.log("ImageLoader::" + s)

    imageLazyLoadComplete: (evt) ->
      targetElement = $(evt.target)

      elementUrl = targetElement.attr('src')
      delete @activeLoaders[elementUrl]
      targetElement.remove()
      @loadedImages[elementUrl] = true

      @logToConsole "new methodology - loaded: [" + elementUrl + "]"

      for plr, i in @postLoadRouters
        @logToConsole "checking plr index [" + i + "]/[" + plr.urls + "]..."
        for url, k in plr.urls
          @logToConsole "   foofoo [" + url + "]/[" + k + "]"
          arrayPos = url.indexOf(elementUrl)
          @logToConsole "past indexOf!"

          if (arrayPos != -1)
            @postLoadRouters[i].urls.splice(k, 1)

            if @postLoadRouters[i].urls.length == 0
              @logToConsole "all in this section are done; break!"
              cb = plr.callback
              @postLoadRouters.splice(i, 1)

              if (cb != null)
                @logToConsole "firing callback!"
                cb()
            else
              @logToConsole "not done yet..."

            return

      @logToConsole "loads are done but nobody cares"

    debugPLR: (foo) ->
      @logToConsole("##### PLR START (" + foo + ")#####")
      for plr, i in @postLoadRouters
        @logToConsole "[" + i + "]"
        
        for u, k in plr.urls
          @logToConsole "     [" + k + "] -> [" + u + "]"
      @logToConsole("##### PLR END #####")

    setupCallbacks: (urls, callback) ->
      # @debugPLR("start")
      # first go through the existing postLoadRouters and clear out any entries relating to any of these urls
      # scenario - we display pair 0, and immediately start preloading pair 1. While that's in progress,
      # user clicks on pair 9. We start loading pair 9 and don't care about when pair 1 finishes.
      for plr, i in @postLoadRouters
        @logToConsole "clearing out old garbage"
        loopUrls = plr.urls

        # remove any instance of the urls in "urls" from the ones stored on this postLoadRouter object
        plr.urls = loopUrls.filter (x) ->
          urls.indexOf(x) == -1

        if (plr.urls.length == 0)
          @postLoadRouters.splice(i, 1)
          break

      # @debugPLR("mid")

      # and now store this info for when the next load completes
      plr = {
        urls: urls
        callback: callback
      }
      @postLoadRouters.push(plr)
      # @debugPLR("end")

    ensureImagesLoaded: (urls, callback = null) ->
      if ImageLoader.DISABLE_PRELOADS
        if (callback != null)
          callback()
        return

      @logToConsole ">>>>> preloading images [" + urls + "] (" + new Date() + ")"
      indexesToLoad = []

      allImagesAlreadyLoaded = true
      plrUrls = []
      for url, i in urls
        if (@loadedImages[url] != true)
          allImagesAlreadyLoaded = false
          @logToConsole "url #" + (i+1) + ": [" + url + "] needs to be loaded..."
          plrUrls.push(url)
          if (@activeLoaders[url] != null)
            # hven't yet tried to load this one
            indexesToLoad.push(i)
          else
            # some earlier process started this one loading...
            @logToConsole "someone already started this load..."

      if allImagesAlreadyLoaded
        @logToConsole "everything already loaded"
        if (callback != null)
          callback()
      else
        if (callback != null)
          @setupCallbacks(plrUrls, callback)

        # start the preload...
        for idx in indexesToLoad
          url = urls[idx]
          onLoadHandler = (evt) => ( @imageLazyLoadComplete(evt) )
          @activeLoaders[url] = $("<img/>").css("display","none").attr("src", url).bind('load', onLoadHandler).appendTo($("body"))


  return ImageLoader
)
