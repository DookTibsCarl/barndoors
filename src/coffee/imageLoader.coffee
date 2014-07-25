###
this class is responsible for handling image preloads. The individual views are set up to expect that when they are
told to display something, it's ok to display it - any preloading has already been done.

controller should treat this as a black box. It can always call "ensureImagesLoaded" and rely on the callback, if any,
being called appropriately, whether the image has been previously cached or is being loaded for the
first time. Likewise individual views don't need to concern themselves with preloading. They can assume that 
when the controller calls their "renderInitialView" or "showNextPair" methods that it's ok to show things.

(rewritten 2014-07-03 to use the "imagesloaded" library from http://desandro.github.io/imagesloaded/
###

define(["../../lib/js/imagesloaded"], (imagesLoaded) ->

  class ImageLoader
    @DISABLE_PRELOADS = false # used for testing only, NEVER SET THIS TO TRUE
    @PRELOADER_DIV_ID = "barndoor_image_preloader"

    constructor: () ->
      @logToConsole "constructing ImageLoader..."
      @imgLoaderArea = $("<div/>").css("display","none").attr("id", ImageLoader.PRELOADER_DIV_ID).appendTo($("body"))

    logToConsole: (s) ->
      console.log("ImageLoader::" + s)

    ensureImagesLoaded: (urls, callback = null) ->
      @logToConsole("loading images: [" + urls + "]")
      if ImageLoader.DISABLE_PRELOADS
        @logToConsole("preloads disabled")
        @logToConsole(if callback == null then "no callback configured" else "firing callback")
        if (callback != null)
          callback()
        return

      tempImages = []
      for url in urls
        tempImages.push($("<img/>").css("display","none").attr("src", url).appendTo(@imgLoaderArea))
        
      imagesLoaded("#" + ImageLoader.PRELOADER_DIV_ID, => (
        tempImage.remove() for tempImage in tempImages
        @logToConsole("all images loaded; " + (if callback == null then "no callback configured" else "firing callback"))
        if callback then callback()
      ))

  return ImageLoader
)
