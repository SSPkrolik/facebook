## Facebook SDK For Android

import jnim

import facebook.types

import sdl2

jnimport:
  import android.content.Intent
  import android.net.Uri
  import android.app.Activity

  proc `parse`(s: typedesc[Uri], str: string): Uri
  proc new(t: typedesc[Intent], name: string, uri: Uri)
  proc startActivity(a: Activity, i: Intent)

proc run*(loginDialog: LoginDialog, callback: proc(response: string)) =
  ## Perform login into Facebook
  let
    browserUrl:  Uri    = Uri.`parse`(loginDialog.loginUrl())
    loginIntent: Intent = Intent.new("android.intent.action.VIEW", browserUrl)

  let activity = androidGetActivity().Activity
  activity.startActivity(loginIntent)
