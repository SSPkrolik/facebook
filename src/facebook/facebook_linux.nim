## Linux implementation for Facebook SDK
import nuuid
import os
import osproc
import streams
import strutils
import uri

import facebook.types

proc run*(loginDialog: LoginDialog, callback: proc(response: string)) =
  ## Perform login into Facebook
  if execShellCmd("xdg-open '$#'" % [loginDialog.loginURL()]) != 0:
    raise newException(Exception, "Error opening login dialog in browser")
  else:
    discard
