## Common Facebook Types

import nuuid
import strutils
import uri

const
  SKUnknown*:       string = "unknown"
  SKNotAuthorized*: string = "not_authorized"
  SKConnected*:     string = "connected"

  LoginButtonSmall*:  string = "small"
  LoginButtonMedium*: string = "medium"
  LoginButtonLarge*:  string = "large"
  LoginButtonXlarge*: string = "xlarge"

  AudienceEveryone*: string = "everyone"
  AudienceFriends*:  string = "friends"
  AudienceOnlyMe*:   string = "only_me"

  FacebookUriScheme* = "https"
  FacebookUriDomain* = "www.facebook.com"

type FacebookVersion* {.pure.} = enum
    v20 = "v2.0"
    v21 = "v2.1"
    v22 = "v2.2"
    v23 = "v2.3"
    v24 = "v2.4"

proc lastVersion*(): FacebookVersion = high(FacebookVersion)
    ## Returns last supported version of Facebook API

type
  LoginDialogResponseType* {.pure.} = enum
    Token        = "token"
    Code         = "code"
    TokenAndCode = "code%20token"

type
  LoginDialog* = ref object
    appId*:        string      ## Facebook App ID
    redirectUri*:  Uri         ## Redirect Uri after logging into FB
    state*:        string      ## CSRF protection token
    scope:         seq[string] ## Comma-separated list of access rights

proc newLoginDialog*(appId: string, redirectUri: string, responseType: LoginDialogResponseType, scope: seq[string]): LoginDialog =
  ## LoginDialog constructor
  result.new
  result.appId = appId
  result.redirectUri = parseUri(redirectUri)
  result.state = generateUUID()
  result.scope = scope

proc scope*(loginDialog: LoginDialog): string = join(loginDialog.scope, ",")
  ## Build scope string from sequence

proc loginUrl*(loginDialog: LoginDialog): string =
  ## Build Facebook login URL
  return "https://www.facebook.com/dialog/oauth?client_id=$#&redirect_uri=$#&scope=$#&state=$#" % [
    loginDialog.appId,
    $loginDialog.redirectUri,
    loginDialog.scope.join(","),
    loginDialog.state
  ]
