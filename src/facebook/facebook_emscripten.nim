## Facebook SDK For JavaScript (Emscripten)
import macros
import times
import strutils

import emscripten
import jsbind

import facebook.types

proc hasOwnProperty(o: JSObj, prop: string): bool {.jsimport.}

type AuthResponse* = ref object of JSObj
    ## Response from Facebook HTTP API gateway

proc accessToken*(ar: AuthResponse): string {.jsimportProp} 
proc expiresIn*(ar: AuthResponse): cint {.jsimportProp} 
proc signedRequest*(ar: AuthResponse): string {.jsimportProp} 
proc userID*(ar: AuthResponse): string {.jsimportProp} 

type LoginStatusResponse* = ref object of JSObj
    ## Information we get about user login status from Facebook's
    ## AuthResponse object

proc status*(ls: LoginStatusResponse): string {.jsimportProp.}
proc authResponse*(ls: LoginStatusResponse): AuthResponse {.jsimportProp.}

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

proc emptyJSObj(): JSObj {.jsimportgWithName: "function() { return {}; }".}

proc newFacebookInfoPrivate(): FacebookInfo {.jsimportgWithName: "function() { return {}; }".}
proc newFacebookInfo*(appId: string, cookie: bool, xfbml: bool, version: FacebookVersion): FacebookInfo =
    result = newFacebookInfoPrivate()
    result.appId = appId
    result.cookie = if cookie: 1.EM_BOOL else: 0.EM_BOOL
    result.xfbml = if xfbml: 1.EM_BOOL else: 0.EM_BOOL
    result.version = $version


type FacebookApiResponseError* = ref object of JSObj
    ## Facebook can sometimes return API call errors
    ## `error` field in FacebookApiResponse holds the info
    ## on that error.

proc code*(err: FacebookApiResponseError): int {.jsimportProp.}

type FacebookApiResponse* = ref object of JSObj
    ## Facebook Graph API response object

proc error*(resp: FacebookApiResponse): FacebookApiResponseError {.jsimportProp.}

type FacebookUserPictureInfo* = ref object of JSObj

proc url*(info: FacebookUserPictureInfo): string {.jsimportProp.}

type FacebookApiProfilePictureResponse* = ref object of JSObj

proc data*(resp: FacebookApiProfilePictureResponse): FacebookUserPictureInfo {.jsimportProp.}
proc error*(resp: FacebookApiProfilePictureResponse): FacebookApiResponseError {.jsimportProp.}

type FacebookApiParams = ref object of JSObj

proc newFacebookApiParams(): FacebookApiParams {.jsimportgWithName: "function() { return {}; }".}
proc `redirect=`(params: FacebookApiParams, value: int) {.jsimportProp.}
proc redirect(params: FacebookApiParams): int {.jsimportProp.}


type FacebookSdk* = ref object of JSObj
    ## Just JavaScript object. In Facebook SDK is expressed via
    ## global `FB` variable, and is a singleton.
    ## User `FB` variable, not referencing to FacebookApi type
    ## directly.

# Wrappers for Private SDK API

proc init(fb: FacebookSdk, fi: FacebookInfo) {.jsImport.}
proc getLoginStatus(fb: FacebookSdk, callback: proc(response: LoginStatusResponse)) {.jsImport.}
proc login(fb: FacebookSdk, callback: proc(response: LoginStatusResponse)) {.jsImport.}
proc logout(fb: FacebookSdk, callback: proc(response: AuthResponse)) {.jsImport.}

proc apiUserpic(fb: FacebookSdk, path: string, meth: string, params: JSObj, callback: proc(response: FacebookApiProfilePictureResponse)) {.jsimportWithName: "api".}

type Window = ref object of JSObj
    ## Browser window in JavaScript.

proc `fbAsyncInit=`*(w: Window, cb: proc()) {.jsimportProp.}

var 
    FB*: FacebookSdk = nil
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

proc initializeFacebook*(fi: FacebookInfo, onInit: proc()) =
    jsRef(onInit)

    let cb = proc() {.cdecl.} =
        if FB.isNil():
            FB = globalEmbindObject(FacebookSdk, "FB")
        FB.init(fi)
        onInit()
    jsRef(cb)

    window.fbAsyncInit = cb

    nim_fb_load_api_async("script", "facebook-jssdk") # Load Facebook SDK

proc getLoginStatus*(callback: proc(response: LoginStatusResponse)) =
    jsRef(callback)
    if not FB.isNil():
        FB.getLoginStatus(callback)

proc login*(callback: proc(response: LoginStatusResponse)) =
    jsRef(callback)
    FB.login(callback)

proc logout*(callback: proc(response: AuthResponse)) =
    jsRef(callback)
    FB.logout(callback)

import nimx.system_logger

proc userpic*(userId: string, callback: proc(source: string)) =
    ## Get source of user's profile picture and pass it to callback
    ## which processes it according to application logic.
    jsRef(callback)

    proc picCallback(response: FacebookApiProfilePictureResponse) =
        if response.hasOwnProperty("error"):
            logi "[Facebook] Response error code: ", response.error.code
            callback(nil)
        else:
            logi "[Facebook] Received profile picture URL: ", response.data.url
            callback(response.data.url)

    jsRef(picCallback)

    let apiParams = newFacebookApiParams()
    apiParams.redirect = 0

    FB.apiUserpic("/$#/picture" % [userId], "get", apiParams, picCallback)

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