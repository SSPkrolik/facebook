## Cross-Platform Facebook API
import facebook.types
export types

when defined(js):
    const facebookSupported*: bool = false
    import facebook_js
    export facebook_js

elif defined(emscripten):
    const facebookSupported*: bool = true
    import facebook_emscripten
    export facebook_emscripten

elif defined(android):
    const facebookSupported*: bool = false
#    import facebook_android
#    export facebook_android

elif defined(linux):
    const facebookSupported*: bool = false
    import facebook_linux
    export facebook_linux

else:
    const facebookSupported*: bool = false
    {.hint: "This platform is still usupported by 'facebook' package".}
