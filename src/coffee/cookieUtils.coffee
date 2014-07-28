
define([], () ->

  class CookieUtils
    @createExpiryTimeInDays: (days) ->
      return days * 24 * 60 * 60 * 1000

    @createCookie: (name, value, expiryTime) ->
      console.log("set cookie [" + name + "]=[" + value + "], expiry [" + expiryTime + "]")
      if (expiryTime != null)
        d = new Date()
        d.setTime(d.getTime() + expiryTime)
        expires = "; expires=" + d.toGMTString()
      else
        expires = ""
      document.cookie = name + "=" + value + expires + "; path=/; domain=.carleton.edu"
      # console.log("after create cookie: [" + document.cookie + "]")

    @readCookie: (name) ->
      nameEq = name + "="
      ca = document.cookie.split(";")
      for c in ca
        while c.charAt(0) == ' '
          c = c.substring(1, c.length)
        if (c.indexOf(nameEq) == 0)
          return c.substring(nameEq.length, c.length)

    @eraseCookie: (name) ->
      CookieUtils.createCookie(name,"",-1)

  return CookieUtils
)
