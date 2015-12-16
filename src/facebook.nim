## Facebook SDK Public API

import dom
import times

const
  SKUnknown*       : cstring = "unknown"
  SKNotAuthorized* : cstring = "not_authorized"
  SKConnected*     : cstring = "connected"

type
  AuthResponse* {.importc.} = ref object
    accessToken*   {.importc.}: cstring ## Access Token for API usage
    expiresIn*     {.importc.}: int64   ## UNIX time in which login session exprires
    signedRequest* {.importc.}: cstring ## Client (person) data
    userID*        {.importc.}: cstring ## Client's user ID

  LoginStatus* {.importc.} = ref object
    status* {.importc.}: cstring
    authResponse*: AuthResponse

  FacebookInfo* {.importc.} = ref object of RootObj
    ## Facebook Client
    appId*   {.importc.}: cstring
    cookie*  {.importc.}: bool
    xfbml*   {.importc.}: bool
    version* {.importc.}: cstring

# `FB` object binding
var FB* {.importc, nodecl.}: ref RootObj
proc init*(fb: ref object, info: FacebookInfo) {.importc, nodecl.}
proc getLoginStatus*(fb: ref object, callback: proc(response: LoginStatus)) {.importc, nodecl.}

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

proc login*(onLoggedIn: proc(status: LoginStatus)) =
  ## Login
  {.emit: """
  FB.getLoginStatus(`onLoggedIn`);
  """.}
