# super garbagey test view to work out some of the kinks and flow 
# around switching between view types on screen resize
define(["view/baseview"], (BaseView) ->
  class SimpleView extends BaseView
    constructor: (@mainController, @targetDivName, @imgAspectRatio) ->
      # @$ = jq
      @targetDiv = $("##{@targetDivName}")
      @logToConsole "constructing simple view!"

      someWidth = "200px"
      # @targetDiv.css({ "background-color": "", "overflow": "hidden", "position": "absolute" })

      for side in ["left", "right"]
        slideContainer = $("<div/>").attr("id", "slide#{side}Container").appendTo(@targetDiv)
        img = $("<img/>").attr("id", "img#{side}Container").appendTo(slideContainer)
        header = $("<div/>").attr("id", "label#{side}Container").appendTo(slideContainer)
        details = $("<div/>").attr("id", "desc#{side}Container").appendTo(slideContainer)

        slideStyle = { float: "left", "padding": "10px" }
        imgStyle = { width: someWidth }
        headerStyle = { font: "20px Helvetica", width: someWidth, height: "50px", "background-color": "gray" }
        detailStyle = { width: someWidth, height: "100px", "background-color": "yellow" }

        slideContainer.css(slideStyle)
        img.css(imgStyle)
        header.css(headerStyle)
        details.css(detailStyle)

    renderInitialView: (pair) ->
      @showNextPair(0, pair)

    showNextPair: (index, pair, reversing = false) ->
      @leftSlide = pair.leftSlide
      @rightSlide = pair.rightSlide
      @logToConsole "SHOWING [" + @leftSlide.title + "]/[" + @rightSlide.title + "]"

      $("#imgleftContainer").attr("src", @leftSlide.imgUrl);
      $("#imgrightContainer").attr("src", @rightSlide.imgUrl);

      $("#labelleftContainer").html(@leftSlide.title)
      $("#labelrightContainer").html(@rightSlide.title)

      $("#descleftContainer").html(@leftSlide.details)
      $("#descrightContainer").html(@rightSlide.details)


    pseudoDestructor: ->
      @logToConsole "cleaning up custom simple..."
      $("##{@targetDivName} > div").remove()
      super

  return SimpleView
)
