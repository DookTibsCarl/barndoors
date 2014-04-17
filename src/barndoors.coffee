###
  dependencies: JQuery
###

class BarnDoors
  constructor: (@targetDivName) ->
    console.log "constructing barn door object, will go into '#{targetDivName}' div..."

    # set a local alias for jQuery
    @$ = jQuery
    console.log "jquery is [#{$}]"
    @setup()

  setup: ->
    console.log "performing setup"
    targetDiv = $("##{@targetDivName}")
    # console.log "targetDiv [" + targetDiv + "], [" + targetDiv.length + "]"
    targetDiv.css "background-color", "gray"

    ###
    # this works great if I --join all coffee during compilation. But I am not sure I want to do that...
    p = new BDPoint(42, 21)
    p.printCoords()
    ###

    # this works great if we have a line like '@foobar = BDPoint' in point.coffee
    # p = new foobar(9, 11)
    # p = new foobar.delve.deeper(8, 11)

    # p = new edu_carleton_barndoors_model_Point(5, 31)
    # p.printCoords()

    p = new edu.carleton.barndoors.model.Point(77, 99)
    p.printCoords()
     

  handshake: (x) ->
    console.log "inside BarnDoors handshake fxn with '#{x}' passed in"
    "handshake made with namespace and auto recompile and maps!"


# expose the class so it's usable from window.BarnDoorsAPI
# @BarnDoorsAPI = BarnDoors
# in JS, accessible via something like "var bd = new window.BarnDoorsAPI();"

# expose the class so it's usable from (window.)edu.carleton.BarnDoors
# in JS, accessible via something like "var bd = new edu.carleton.BarnDoors("someArg");"
###
@edu =
  carleton:
    barndoors:
      controller: BarnDoors
###
# namespaced; dots replaced with underscores. Must be a better way of doing this?
# @edu_carleton_barndoors_controller_BarnDoors = BarnDoors

# special - barndoors.coffee gets included first and sets up the general export "package" structure
# still seems sorta wonky - what if barndoors.js isn't completely loaded first?
@edu =
  carleton:
    barndoors:
      controller: BarnDoors
      model: {}

###
packageStructure =
  edu:
    carleton:
      barndoors:
        controller: BarnDoors

if (@edu?)
  @edu.carleton.barndoors.controller = BarnDoors
else
  @edu = packageStructure.edu
  ###

console.log ">>>> barndoors lib included..."
