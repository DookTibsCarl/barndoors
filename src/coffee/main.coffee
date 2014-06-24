# IE8/9 don't have console.log defined unless you open F12 dev tools; stub out to avoid errors
window.console = window.console || { log: () -> }


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
