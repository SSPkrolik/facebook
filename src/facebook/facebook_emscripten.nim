## Facebook SDK For JavaScript (Emscripten)
import macros
import times
import strutils

import emscripten
import jsbind

import facebook.types

type AuthResponse* = ref object of JSObj
    ## Response from Facebook HTTP API gateway

proc accessToken*(ar: AuthResponse): string {.jsimportProp} 
proc expiresIn*(ar: AuthResponse): cint {.jsimportProp} 
proc signedRequest*(ar: AuthResponse): string {.jsimportProp} 
proc userID*(ar: AuthResponse): string {.jsimportProp} 

type LoginStatus* = ref object of JSObj
    ## Information we get about user login status from Facebook's
    ## AuthResponse object

proc status*(ls: LoginStatus): string {.jsimportProp.}
proc authResponse*(ls: LoginStatus): AuthResponse {.jsimportProp.}

type FacebookInfo* = ref object of JSObj
    ## Technical information about current state of Facebook
    ## server API we are calling

proc appId*(fi: FacebookInfo): string {.jsimportProp.}
proc cookie*(fi: FacebookInfo): EM_BOOL {.jsimportProp.}
proc xfbml*(fi: FacebookInfo): EM_BOOL {.jsimportProp.}
proc version*(fi: FacebookInfo): string {.jsimportProp.}

proc `appId=`*(fi: FacebookInfo, appId: string) {.jsimportProp.}
proc `cookie=`*(fi: FacebookInfo, cookie: EM_BOOL) {.jsimportProp.}
proc `xfbml=`*(fi: FacebookInfo, xfbml: EM_BOOL) {.jsimportProp.}
proc `version=`*(fi: FacebookInfo, version: string) {.jsimportProp.}

proc newFacebookInfoPrivate(): FacebookInfo {.jsimportgWithName: "function() { return {}; }".}
proc newFacebookInfo*(appId: string, cookie: bool, xfbml: bool, version: FacebookVersion): FacebookInfo =
    result = newFacebookInfoPrivate()
    result.appId = appId
    result.cookie = if cookie: 1.EM_BOOL else: 0.EM_BOOL
    result.xfbml = if xfbml: 1.EM_BOOL else: 0.EM_BOOL
    result.version = $version

type FacebookJSAPI = ref object of JSObj
    ## Just JavaScript object. In Facebook SDK is expressed via
    ## global `FB` variable, and is a singleton.
    ## User `FB` variable, not referencing to FacebookJSAPI type
    ## directly.

proc init*(fb: FacebookJSAPI, fi: FacebookInfo) {.jsImport.}
proc getLoginStatus(fb: FacebookJSAPI, callback: proc(response: LoginStatus)) {.jsImport.}
proc login(fb: FacebookJSAPI, callback: proc(response: AuthResponse)) {.jsImport.}
proc logout(fb: FacebookJSAPI, callback: proc(response: AuthResponse)) {.jsImport.}

type Window = ref object of JSObj
    ## Browser window in JavaScript.

proc `fbAsyncInit=`*(w: Window, cb: proc()) {.jsimportProp.}

var 
    FB*: FacebookJSAPI = nil
        ## `FB` is a global JavaScript object which gives access
        ## to overall Facebook SDK APIs

    window*: Window = globalEmbindObject(Window, "window")
        ## `window` is JavaScript object that expresses browser's
        ## window

let nim_fb_load_api_async = proc(s: string, id: string) =
    ## Asynchronous Facebook SDK loading proc
    discard EM_ASM_INT("""
    var fjs = document.getElementsByTagName(Pointer_stringify($0))[0];
    var js = null;
    if (document.getElementById(Pointer_stringify($1)) != null) {
        return;
    } else {
        js = document.createElement(Pointer_stringify($0));
        js.setAttribute("id", Pointer_stringify($1));
        js.setAttribute("src", "//connect.facebook.net/en_US/sdk.js")
    }

    fjs.parentNode.insertBefore(js, fjs);
    """, cstring(s), cstring(id))

nim_fb_load_api_async("script", "facebook-jssdk") # Load Facebook SDK

proc initializeFacebook*(fi: FacebookInfo, onInit: proc()) =
    if FB.isNil():
        FB = globalEmbindObject(FacebookJSAPI, "FB")
    jsRef(onInit)

    let cb = proc() {.cdecl.} =
        FB.init(fi)
        onInit()
    jsRef(cb)

    window.fbAsyncInit = cb

proc getLoginStatus*(onLoggedIn: proc(response: LoginStatus)) =
    jsRef(onLoggedIn)
    if not FB.isNil():
        FB.getLoginStatus(onLoggedIn)

proc login*(callback: proc(response: AuthResponse)) =
    jsRef(callback)
    FB.login(callback)

proc logout*(callback: proc(response: AuthResponse)) =
    jsRef(callback)
    FB.logout(callback)

proc loginUI*(onLogin: proc(), autoLogoutLink: bool = true, maxRows: int = 1, scope: seq[string] = @["public_profile"], size: string = LoginButtonSmall, showFaces: bool = false, defaultAudience: string = "friends"): pointer =
    ## Build Login UI - "blue button"
    #[
    let scopeStr = join(scope, ",")
    EM_ASM_INT("""
    var btn = document.createElement("fb:login-button")
    btn.setAttribute("auto-logout-link", $autoLogoutLink)
    btn.setAttribute("max-rows", $maxRows)
    btn.setAttribute("scope", scopeStr)
    btn.setAttribute("size", size.cstring)
    btn.setAttribute("show-faces", $showFaces)
    btn.setAttribute("default-audience", defaultAudience.cstring)
    """)
    return nil
    ]#
    return nil