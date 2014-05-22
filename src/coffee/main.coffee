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
