## Facebook SDK For Linux (Desktop)

import nuuid
import os
import osproc
import streams
import strutils
import uri

import facebook.types

type FacebookNotInitialized = object of Exception
    ## Raised when trying to call FB API without initializing it

type FacebookInfo* = ref object
    appId:  string
    cookie:  bool
    xfbml:   bool
    version: FacebookVersion

proc appId*(fi: FacebookInfo): string = fi.appId
proc cookie*(fi: FacebookInfo): bool = fi.cookie
proc xfbml*(fi: FacebookInfo): bool = fi.xfbml
proc version*(fi: FacebookInfo): string = $fi.version

proc newFacebookInfo*(appId: string, cookie: bool, xfbml: bool, version: FacebookVersion): FacebookInfo =
    result.new()
    result.appId   = appId
    result.cookie  = cookie
    result.xfbml   = xfbml
    result.version = version

type LoginStatusResponse* = ref object
    ## TODO: implement fields

type LogoutStatusResponse* = ref object
    ## TODO: implement fields

type FacebookSDK = ref object
    initialized: bool
    info:        FacebookInfo

proc newFacebookSDK(fi: FacebookInfo): FacebookSDK =
    result.new()
    result.info = fi
    result.initialized = true

proc isInitialized(fb: FacebookSDK): bool =
    if fb.isNil():
        return false
    else:
        return fb.initialized

var FB*: FacebookSDK

proc initializeFacebook*(fi: FacebookInfo, onInit: proc()) =
    if FB.isNil():
        FB = newFacebookSDK(fi)
        onInit()
    elif not FB.initialized:
        onInit()
    else:
        discard

template initCheckAndRaise(body: untyped) =
    if not FB.isInitialized():
        raise newException(FacebookNotInitialized, "You need to call facebook.api.initializeFacebook(...) before using its API calls.")
    else:
        body

proc login(fb: FacebookSDK, callback: proc(response: LoginStatusResponse)) =
    ## TODO: implement login

proc logout(fb: FacebookSDK, callback: proc(response: LogoutStatusResponse)) =
    ## TODO: implement logout

# Public API

proc login*(callback: proc(response: LoginStatusResponse)) =
    ## FB.login(callback)

proc logout*(callback: proc(response: LogoutStatusResponse)) =
    ## FB.logout(callback)

proc run*(loginDialog: LoginDialog, callback: proc(response: string)) =
  ## Perform login into Facebook
  if execShellCmd("xdg-open '$#'" % [loginDialog.loginURL()]) != 0:
    raise newException(Exception, "Error opening login dialog in browser")
  else:
    discard
