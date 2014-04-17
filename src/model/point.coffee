class BDPoint
  constructor: (@x, @y) ->

  printCoords: ->
    console.log "{point x=#{@x}, y=#{@y}}"

@edu.carleton.barndoors.model.Point = BDPoint

console.log ">>>> point lib included..."
