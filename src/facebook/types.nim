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

  FacebookVersion22*: string = "v2.2"
  FacebookVersion23*: string = "v2.3"
  FacebookVersion24*: string = "v2.4"
  FacebookVersion25*: string = "v2.5"

  FacebookUriScheme* = "https"
  FacebookUriDomain* = "www.facebook.com"

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
