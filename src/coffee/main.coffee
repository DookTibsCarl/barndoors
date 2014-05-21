kickoff = (cfg) ->
  require(["controller"], (BarnDoorController) ->
    bdc = new BarnDoorController()
    bdc.setup(cfg)
  )

# first decision - do we need to load jquery ourselves, or is is already loaded?
jqPath = bdConfigObj.jqueryLoadPath
if (jqPath and jqPath != "")
  require([jqPath], (invalidJqueryReference) -> kickoff(bdConfigObj))
else
  kickoff(bdConfigObj)
