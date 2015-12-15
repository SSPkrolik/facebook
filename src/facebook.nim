## Facebook SDK Public API

import times

type
  LoginStatusKind* {.pure.} = enum
    Unknown       = "unknown"
    NotAuthorized = "not_authorized"
    Connected     = "connected"

  AuthResponse = object
    accessToken*:   string        ## Access Token for API usage
    expiresIn*:     TimeInterval  ## UNIX time in which login session exprires
    signedRequest*: string        ## Client (person) data
    userID*:         string       ## Client's user ID

  LoginStatus* = object
    case status*: LoginStatusKind
    of LoginStatusKind.Connected:
      authResponse*: AuthResponse
    else:
      discard

  FacebookClient* = ref object of RootObj
    ## Facebook Client
    appId*:   string
    cookie*:  bool
    xfbml*:   bool
    version*: string

var
  Facebook*: FacebookClient = nil

#
# JavaScript Implementation for Facebook Client
#
when defined(js):
  import dom

  let nim_fb_load_api_async = proc(d: Document, s: string, id: string) =
    ## Asynchronous Facebook SDK loading proc
    let scriptElements = d.getElementsByTagName(s)[0]
    var
      js  = scriptElements[0]
      fjs = scriptElements[1]
    if d.getElementById(id) != nil:
      return

    js = d.createElement(s)
    js.id = id
    js.src = "//connect.facebook.net/en_US/sdk.js"

    fjs.parentNode.insertBefore(js, fjs)

  nim_fb_load_api_async() # Load Facebook SDK

  proc init*(appId: string, cookie: bool, xfbml: true, version: string) =
    ## Asynchronous Facebook SDK Initialization
    Facebook.new

    Facebook.appId = appId
    Facebook.cookie = cookie
    Facebook.xfbml = xfbml
    Facebook.version = version

    window.fbAsyncInit = proc() =
      FB.init(Facebook)

  proc login*(fb: FacebookType, callback: proc(response: AuthResponse)) =
    ## Login
    FB.getLoginStatus(callback)
