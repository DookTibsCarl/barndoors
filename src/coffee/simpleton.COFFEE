# test file for sourcemap optimizations
define([""], () ->
  class Simpleton
    doSomething: () ->
      console.log("simpleton.doSomething!")
      return null

  return Simpleton
)
