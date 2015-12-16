## Facebook SDK Public API

import dom
import times
import strutils

const
  SKUnknown*:       string = "unknown"
  SKNotAuthorized*: string = "not_authorized"
  SKConnected*:     string = "connected"

const
  LoginButtonSmall*:  string = "small"
  LoginButtonMedium*: string = "medium"
  LoginButtonLarge*:  string = "large"
  LoginButtonXlarge*: string = "xlarge"

const
  AudienceEveryone*: string = "everyone"
  AudienceFriends*:  string = "friends"
  AudienceOnlyMe*:   string = "only_me"

const
  FacebookVersion22*: string = "v2.2"
  FacebookVersion23*: string = "v2.3"
  FacebookVersion24*: string = "v2.4"
  FacebookVersion25*: string = "v2.5"

type
  AuthResponse* {.importc.} = ref object
    accessToken*   {.importc.}: cstring ## Access Token for API usage
    expiresIn*     {.importc.}: int64   ## UNIX time in which login session exprires
    signedRequest* {.importc.}: cstring ## Client (person) data
    userID*        {.importc.}: cstring ## Client's user ID

  LoginStatus* {.importc.} = ref object
    status*       {.importc.}: cstring
    authResponse* {.importc.}: AuthResponse

  FacebookInfo* {.importc.} = ref object of RootObj
    ## Facebook Client
    appId*   {.importc.}: cstring
    cookie*  {.importc.}: bool
    xfbml*   {.importc.}: bool
    version* {.importc.}: cstring

# `FB` object binding
var FB {.importc, nodecl.}: ref RootObj
proc init(fb: ref object, info: FacebookInfo) {.importc, nodecl.}
proc getLoginStatus(fb: ref object, callback: proc(response: LoginStatus)) {.importc, nodecl.}
proc logout(fb: ref object, callback: proc(response: LoginStatus)) {.importc, nodecl.}

let nim_fb_load_api_async = proc(d: Document, s: string, id: string) =
  ## Asynchronous Facebook SDK loading proc
  var
    fjs: Element = d.getElementsByTagName(s)[0]
    js:  Element = nil
  if d.getElementById(id) != nil:
    return

  js = d.createElement(s)
  js.setAttribute("id", id)
  js.setAttribute("src", "//connect.facebook.net/en_US/sdk.js")

  fjs.parentNode.insertBefore(js, fjs)

nim_fb_load_api_async(document, "script", "facebook-jssdk") # Load Facebook SDK

proc initializeFacebook*(fi: FacebookInfo, onInit: proc()) =
  {.emit: """
  window.fbAsyncInit = function() {
    FB.init(`fi`);
    `onInit`();
  }
  """.}

proc getLoginStatus*(onLoggedIn: proc(response: LoginStatus)) =
  ## Login
  {.emit: """
  FB.getLoginStatus(`onLoggedIn`);
  """.}

proc logout*() =
  FB.logout(proc(response: ref object) = discard)

proc loginUI*(onLogin: proc(), autoLogoutLink: bool = true, maxRows: int = 1, scope: seq[string] = @["public_profile"], size: string = LoginButtonSmall, showFaces: bool = false, defaultAudience: string = "friends"): Element =
  ## Build Login UI - "blue button"
  let scopeStr = join(scope, ",")
  var btn = document.createElement("fb:login-button")
  btn.setAttribute("auto-logout-link", $autoLogoutLink)
  btn.setAttribute("max-rows", $maxRows)
  btn.setAttribute("scope", scopeStr)
  btn.setAttribute("size", size.cstring)
  btn.setAttribute("show-faces", $showFaces)
  btn.setAttribute("default-audience", defaultAudience.cstring)
  return btn
