## Example of cross-platform Facebook SDK
import facebook.api

import parseopt

proc main() =
  # Building login dialog settings
  let loginDialog = newLoginDialog(
    appId = "{facebook-app-id}", 
    redirectUri = "{redirect-url-of-your-server-of-registered-app}", # http://localhost:5001/auth/fb/login-callback,
    LoginDialogResponseType.Code,
    scope = @["public_profile"]
  )

  # Perform asynchronous login procedure
  loginDialog.run(proc(response: string) = discard)

when isMainModule:
  main()
