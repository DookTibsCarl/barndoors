define(["view/animatedview"], (AnimatedView) ->
  class FullTextBelowAnimatedView extends AnimatedView

    constructor: (@mainController, @targetDivName, @imageAspectRatio) ->
      super(@mainController, @targetDivName, @imageAspectRatio)

    enforceAspectRatio: () ->
      @targetDiv.height(@targetDiv.width())

  return FullTextBelowAnimatedView
)
