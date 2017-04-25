## Facebook SDK For JavaScript (Emscripten)
import macros
import times
import strutils

import jsbind.emscripten
import jsbind

import facebook.types

proc hasOwnProperty(o: JSObj, prop: string): bool {.jsimport.}

type AuthResponse* = ref object of JSObj
    ## Response from Facebook HTTP API gateway

proc accessToken*(ar: AuthResponse): string {.jsimportProp}
proc expiresIn*(ar: AuthResponse): int {.jsimportProp}
proc signedRequest*(ar: AuthResponse): string {.jsimportProp}
proc userID*(ar: AuthResponse): string {.jsimportProp}

type LoginStatusResponse* = ref object of JSObj
    ## Information we get about user login status from Facebook's
    ## AuthResponse object

proc status*(ls: LoginStatusResponse): string {.jsimportProp.}
proc authResponse*(ls: LoginStatusResponse): AuthResponse {.jsimportProp.}

type LogoutStatusResponse* = ref object of JSObj

type FacebookInfo* = ref object of JSObj
    ## Technical information about current state of Facebook
    ## server API we are calling

proc appId*(fi: FacebookInfo): string {.jsimportProp.}
proc cookie*(fi: FacebookInfo): bool {.jsimportProp.}
proc xfbml*(fi: FacebookInfo): bool {.jsimportProp.}
proc version*(fi: FacebookInfo): string {.jsimportProp.}

proc `appId=`*(fi: FacebookInfo, appId: string) {.jsimportProp.}
proc `cookie=`*(fi: FacebookInfo, cookie: bool) {.jsimportProp.}
proc `xfbml=`*(fi: FacebookInfo, xfbml: bool) {.jsimportProp.}
proc `version=`*(fi: FacebookInfo, version: string) {.jsimportProp.}

proc emptyJSObj(): JSObj {.jsimportgWithName: "function() { return {}; }".}

proc newFacebookInfoPrivate(): FacebookInfo {.jsimportgWithName: "function() { return {}; }".}
proc newFacebookInfo*(appId: string, cookie: bool, xfbml: bool, version: FacebookVersion): FacebookInfo =
    result = newFacebookInfoPrivate()
    result.appId = appId
    result.cookie = cookie
    result.xfbml = xfbml
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
proc logout(fb: FacebookSdk, callback: proc(response: LogoutStatusResponse)) {.jsImport.}

proc apiUserpic(fb: FacebookSdk, path: string, meth: string, params: FacebookApiParams, callback: proc(response: FacebookApiProfilePictureResponse)) {.jsimportWithName: "api".}

type Window = ref object of JSObj
    ## Browser window in JavaScript.

proc `fbAsyncInit=`*(w: Window, cb: proc()) {.jsimportProp.}

proc nim_fb_load_api_async(s: string, id: string) =
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
    var cb: proc()
    cb = proc() =
        globalEmbindObject(FacebookSdk, "FB").init(fi)
        onInit()
        jsUnref(cb)
    jsRef(cb)

    globalEmbindObject(Window, "window").fbAsyncInit = cb

    nim_fb_load_api_async("script", "facebook-jssdk") # Load Facebook SDK

proc getLoginStatus*(callback: proc(response: LoginStatusResponse)) =
    var cb: proc(response: LoginStatusResponse)
    cb = proc(response: LoginStatusResponse) =
        callback(response)
        jsUnref(cb)
    jsRef(cb)

    globalEmbindObject(FacebookSdk, "FB").getLoginStatus(cb)

proc login*(callback: proc(response: LoginStatusResponse)) =
    var cb: proc(response: LoginStatusResponse)
    cb = proc(response: LoginStatusResponse) =
        callback(response)
        jsUnref(cb)
    jsRef(cb)

    globalEmbindObject(FacebookSdk, "FB").login(cb)

proc logout*(callback: proc(response: LogoutStatusResponse)) =
    var cb: proc(response: LogoutStatusResponse)
    cb = proc(response: LogoutStatusResponse) =
        callback(response)
        jsUnref(cb)
    jsRef(cb)

    globalEmbindObject(FacebookSdk, "FB").logout(cb)

proc userpic*(userId: string, pictureType: FacebookUserPicture = FacebookUserPicture.small, callback: proc(source: string)) =
    ## Get source of user's profile picture and pass it to callback
    ## which processes it according to application logic.

    var picCallback: proc(response: FacebookApiProfilePictureResponse)
    picCallback = proc(response: FacebookApiProfilePictureResponse) =
        if response.hasOwnProperty("error"):
            callback(nil)
        else:
            callback(response.data.url)
        jsUnref(picCallback)

    jsRef(picCallback)

    let apiParams = newFacebookApiParams()
    apiParams.redirect = 0

    var request = ("/$#/picture" % [userId])

    if pictureType != FacebookUserPicture.small:
        request &= ("?type=" & $pictureType)

    globalEmbindObject(FacebookSdk, "FB").apiUserpic(request, "get", apiParams, picCallback)

proc userpicWithSize*(userId: string, height: int, width: int, callback: proc(source: string)) =
    ## Get source of user's profile picture with width and height and pass it to callback
    var picCallback: proc(response: FacebookApiProfilePictureResponse)
    picCallback = proc(response: FacebookApiProfilePictureResponse) =
        if response.hasOwnProperty("error"):
            callback(nil)
        else:
            callback(response.data.url)
        jsUnref(picCallback)

    jsRef(picCallback)

    let apiParams = newFacebookApiParams()
    apiParams.redirect = 0

    var request = ("/$#/picture" % [userId])
    request &= ("?type=" & $FacebookUserPicture.large)
    request &= ("&height=" & $height)
    request &= ("&width=" & $width)

    globalEmbindObject(FacebookSdk, "FB").apiUserpic(request, "get", apiParams, picCallback)

type FacebookUserResponse* = ref object of JSObj

proc name*(response: FacebookUserResponse): string {.jsimportProp.}

proc first_name*(response: FacebookUserResponse): string {.jsimportProp.}

proc apiUser(fb: FacebookSdk, path: string, meth: string, callback: proc(response: FacebookUserResponse)) {.jsimportWithName: "api".}

proc fbUser*(userId: string, args: seq[string], callback: proc(response: FacebookUserResponse)) =
    ## Get user info and pass it to callback
    var cb: proc(response: FacebookUserResponse)
    cb = proc(response: FacebookUserResponse) =
        callback(response)
        jsUnref(cb)
    jsRef(cb)

    var request = ("/$#" % [userId])
    if not args.isNil:
        request &= "?fields="
        for i, arg in args:
            request &= arg
            if i < args.len - 1:
                request &= ","

    globalEmbindObject(FacebookSdk, "FB").apiUser(request, "get", cb)

proc fbUser*(userId: string, callback: proc(response: FacebookUserResponse)) =
    fbUser(userId, nil, callback)

type FacebookUiParams = ref object of JSObj

proc newFacebookUiParams*(): FacebookUiParams {.jsimportgWithName: "function() { return {}; }".}

proc `method=`(params: FacebookUiParams, value: string) {.jsimportProp.}
proc `method`(params: FacebookUiParams): string {.jsimportProp.}

proc `uiMethod=`*(params: FacebookUiParams, value: string) = params.`method` = value
proc uiMethod*(params: FacebookUiParams): string = result = params.`method`

proc `action=`*(params: FacebookUiParams, value: string) {.jsimportProp.}
proc action*(params: FacebookUiParams): string {.jsimportProp.}

proc `product=`*(params: FacebookUiParams, value: string) {.jsimportProp.}
proc product*(params: FacebookUiParams): string {.jsimportProp.}

proc `quantity=`*(params: FacebookUiParams, value: int) {.jsimportProp.}
proc quantity*(params: FacebookUiParams): int {.jsimportProp.}

type FacebookUiResponse* = ref object of JSObj

proc error*(params: FacebookUiResponse): int {.jsimportProp.}
proc error_code*(params: FacebookUiResponse): int {.jsimportProp.}
proc error_message*(params: FacebookUiResponse): int {.jsimportProp.}
proc status*(params: FacebookUiResponse): int {.jsimportProp.}

proc uiCall(fb: FacebookSdk, fp: FacebookUiParams, callback: proc(response: FacebookUiResponse)) {.jsimportWithName: "ui".}

proc uiCall*(params: FacebookUiParams, callback: proc(response: FacebookUiResponse)) =
    var cb: proc(response: FacebookUiResponse)
    cb = proc(response: FacebookUiResponse) =
        callback(response)
        jsUnref(cb)
    jsRef(cb)

    globalEmbindObject(FacebookSdk, "FB").uiCall(params, cb)
