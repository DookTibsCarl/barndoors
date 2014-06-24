# IE8/9 don't have console.log defined unless you open F12 dev tools; stub out to avoid errors
window.console = window.console || { log: () -> }

# indexOf doesn't exist in IE?!?!
if !Array.prototype.indexOf
  Array.prototype.indexOf = (el) ->
    len = this.length >>> 0

    from = Number(arguments[1]) or 0
    from = if from < 0 then Math.ceil(from) else Math.floor(from)
    if from < 0 then from += len

    while from < len
      if from in this and this[from] == el
        return from
      from++
    return -1

if !Array.prototype.filter
  Array.prototype.filter = (fxn) ->
    "use strict"
    if this == undefined or this == null
      throw new TypeError()

    t = Object(this)
    len = t.length >>> 0
    if typeof(fxn) != "function"
      throw new TypeError()

    res = []
    thisArg = if arguments.length >= 2 then arguments[1] else undefined
    i = 0
    while i < len
      if i in t
        val = t[i]

      if fxn.call(thisArg, val, i, t)
        res.push(val)
      i++

    return res

# done with shims


define("bootstrapper", ["module"], (module) ->
  bootstrap = () ->
    kickoff = (cfg) ->
      console.log "new style kickoff 4"
      require(["controller"], (BarnDoorController) ->
        bdc = new BarnDoorController()
        bdc.setup(cfg)
      )

    # first decision - do we need to load jquery ourselves, or is is already loaded?
    cfg = module.config().configObj

    jqPath = cfg.jqueryLoadPath
    if (jqPath and jqPath != "")
      require([jqPath], (invalidJqueryReference) -> kickoff(cfg))
    else
      kickoff(cfg)
  return bootstrap
)

require(["bootstrapper"], (bootstrapper) ->
  bootstrapper()
)

###
# simpler entry method for testing out sourcemap optimizations
require(["simpleton"], (Simpleton) ->
  console.log("sourcemap testing is fun"); console.log("for reals!")
  s = new Simpleton();
  s.doSomething()
  console.log("this variable [" + fake + "] is undeclared!")
  foo = nonExistentFxn()
)
###
