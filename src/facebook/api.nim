## Cross-Platform Facebook API

import facebook.types
export types

when defined(js):
  import facebook_js
  export facebook_js

elif defined(android):
  import facebook_android
  export facebook_android

elif defined(linux):
  import facebook_linux
  export facebook_linux

else:
  error("This platform is still usupported")
