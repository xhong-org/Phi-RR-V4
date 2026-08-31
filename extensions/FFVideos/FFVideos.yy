{
  "$GMExtension": "",
  "%Name": "FFVideos",
  "androidactivityinject": "",
  "androidclassname": "FFVideos",
  "androidcodeinjection": "",
  "androidinject": "",
  "androidmanifestinject": "",
  "androidPermissions": [],
  "androidProps": true,
  "androidsourcedir": "",
  "author": "PhigrosLoader",
  "classname": "",
  "copyToTargets": 72,
  "description": "Windows FFmpeg+D3D11 and Android MediaCodec+OES video playback.",
  "exportToGame": true,
  "extensionVersion": "1.0.0",
  "files": [
    {
      "$GMExtensionFile": "v1",
      "%Name": "FFVideos.dll",
      "constants": [],
      "copyToTargets": 64,
      "filename": "FFVideos.dll",
      "final": "ffvideos_shutdown",
      "functions": [
        {
          "$GMExtensionFunction": "",
          "%Name": "__ffvideos_initialize",
          "argCount": 2,
          "args": [
            1,
            2
          ],
          "documentation": "@param {Pointer} _arg_buffer\r\n@param {Real} _arg_buffer_length\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_initialize",
          "help": "",
          "hidden": true,
          "kind": 4,
          "name": "__ffvideos_initialize",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_open",
          "argCount": 1,
          "args": [
            1
          ],
          "documentation": "@param {String} path\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_open",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_open",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_close",
          "argCount": 1,
          "args": [
            2
          ],
          "documentation": "@param {Real} handle\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_close",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_close",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_play",
          "argCount": 1,
          "args": [
            2
          ],
          "documentation": "@param {Real} handle\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_play",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_play",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_pause",
          "argCount": 1,
          "args": [
            2
          ],
          "documentation": "@param {Real} handle\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_pause",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_pause",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_seek",
          "argCount": 2,
          "args": [
            2,
            2
          ],
          "documentation": "@param {Real} handle\r\n@param {Real} position_ms\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_seek",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_seek",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_prepare_frame",
          "argCount": 3,
          "args": [
            2,
            2,
            2
          ],
          "documentation": "@param {Real} handle\r\n@param {Real} position_ms\r\n@param {Real} timeout_ms\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_prepare_frame",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_prepare_frame",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_set_volume",
          "argCount": 2,
          "args": [
            2,
            2
          ],
          "documentation": "@param {Real} handle\r\n@param {Real} volume\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_set_volume",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_set_volume",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_set_loop",
          "argCount": 2,
          "args": [
            2,
            2
          ],
          "documentation": "@param {Real} handle\r\n@param {Real} enabled\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_set_loop",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_set_loop",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_get_status",
          "argCount": 1,
          "args": [
            2
          ],
          "documentation": "@param {Real} handle\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_get_status",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_get_status",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_get_duration",
          "argCount": 1,
          "args": [
            2
          ],
          "documentation": "@param {Real} handle\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_get_duration",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_get_duration",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_get_position",
          "argCount": 1,
          "args": [
            2
          ],
          "documentation": "@param {Real} handle\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_get_position",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_get_position",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_get_width",
          "argCount": 1,
          "args": [
            2
          ],
          "documentation": "@param {Real} handle\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_get_width",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_get_width",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_get_height",
          "argCount": 1,
          "args": [
            2
          ],
          "documentation": "@param {Real} handle\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_get_height",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_get_height",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_draw",
          "argCount": 7,
          "args": [
            2,
            2,
            2,
            2,
            2,
            2,
            2
          ],
          "documentation": "@param {Real} handle\r\n@param {Real} left\r\n@param {Real} top\r\n@param {Real} right\r\n@param {Real} bottom\r\n@param {Real} alpha\r\n@param {Real} dim\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_draw",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_draw",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_get_error",
          "argCount": 1,
          "args": [
            2
          ],
          "documentation": "@param {Real} handle\r\n@returns {String}",
          "externalName": "__EXT_NATIVE__ffvideos_get_error",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_get_error",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 1
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_shutdown",
          "argCount": 0,
          "args": [],
          "documentation": "@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_shutdown",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_shutdown",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        }
      ],
      "init": "",
      "kind": 1,
      "name": "FFVideos.dll",
      "origname": "",
      "ProxyFiles": [],
      "resourceType": "GMExtensionFile",
      "resourceVersion": "2.0",
      "uncompress": false,
      "usesRunnerInterface": false
    },
    {
      "$GMExtensionFile": "v1",
      "%Name": "FFVideos.ext",
      "constants": [],
      "copyToTargets": 8,
      "filename": "FFVideos.ext",
      "final": "ffvideos_android_shutdown",
      "functions": [
        {
          "$GMExtensionFunction": "",
          "%Name": "__ffvideos_android_initialize",
          "argCount": 2,
          "args": [
            1,
            2
          ],
          "documentation": "@param {Pointer} _arg_buffer\r\n@param {Real} _arg_buffer_length\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_initialize",
          "help": "",
          "hidden": true,
          "kind": 4,
          "name": "__ffvideos_android_initialize",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_android_open",
          "argCount": 1,
          "args": [
            1
          ],
          "documentation": "@param {String} path\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_open",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_android_open",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_android_close",
          "argCount": 1,
          "args": [
            2
          ],
          "documentation": "@param {Real} handle\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_close",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_android_close",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_android_play",
          "argCount": 1,
          "args": [
            2
          ],
          "documentation": "@param {Real} handle\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_play",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_android_play",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_android_pause",
          "argCount": 1,
          "args": [
            2
          ],
          "documentation": "@param {Real} handle\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_pause",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_android_pause",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_android_seek",
          "argCount": 2,
          "args": [
            2,
            2
          ],
          "documentation": "@param {Real} handle\r\n@param {Real} position_ms\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_seek",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_android_seek",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_android_prepare_frame",
          "argCount": 3,
          "args": [
            2,
            2,
            2
          ],
          "documentation": "@param {Real} handle\r\n@param {Real} position_ms\r\n@param {Real} timeout_ms\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_prepare_frame",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_android_prepare_frame",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_android_set_volume",
          "argCount": 2,
          "args": [
            2,
            2
          ],
          "documentation": "@param {Real} handle\r\n@param {Real} volume\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_set_volume",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_android_set_volume",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_android_set_loop",
          "argCount": 2,
          "args": [
            2,
            2
          ],
          "documentation": "@param {Real} handle\r\n@param {Real} enabled\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_set_loop",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_android_set_loop",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_android_get_status",
          "argCount": 1,
          "args": [
            2
          ],
          "documentation": "@param {Real} handle\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_get_status",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_android_get_status",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_android_get_duration",
          "argCount": 1,
          "args": [
            2
          ],
          "documentation": "@param {Real} handle\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_get_duration",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_android_get_duration",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_android_get_position",
          "argCount": 1,
          "args": [
            2
          ],
          "documentation": "@param {Real} handle\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_get_position",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_android_get_position",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_android_get_width",
          "argCount": 1,
          "args": [
            2
          ],
          "documentation": "@param {Real} handle\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_get_width",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_android_get_width",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_android_get_height",
          "argCount": 1,
          "args": [
            2
          ],
          "documentation": "@param {Real} handle\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_get_height",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_android_get_height",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_android_draw",
          "argCount": 7,
          "args": [
            2,
            2,
            2,
            2,
            2,
            2,
            2
          ],
          "documentation": "@param {Real} handle\r\n@param {Real} left\r\n@param {Real} top\r\n@param {Real} right\r\n@param {Real} bottom\r\n@param {Real} alpha\r\n@param {Real} dim\r\n@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_draw",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_android_draw",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_android_get_error",
          "argCount": 1,
          "args": [
            2
          ],
          "documentation": "@param {Real} handle\r\n@returns {String}",
          "externalName": "__EXT_NATIVE__ffvideos_get_error",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_android_get_error",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 1
        },
        {
          "$GMExtensionFunction": "",
          "%Name": "ffvideos_android_shutdown",
          "argCount": 0,
          "args": [],
          "documentation": "@returns {Real}",
          "externalName": "__EXT_NATIVE__ffvideos_shutdown",
          "help": "",
          "hidden": false,
          "kind": 4,
          "name": "ffvideos_android_shutdown",
          "resourceType": "GMExtensionFunction",
          "resourceVersion": "2.0",
          "returnType": 2
        }
      ],
      "init": "",
      "kind": 4,
      "name": "FFVideos.ext",
      "origname": "",
      "ProxyFiles": [],
      "resourceType": "GMExtensionFile",
      "resourceVersion": "2.0",
      "uncompress": false,
      "usesRunnerInterface": false
    }
  ],
  "gradleinject": "",
  "hasConvertedCodeInjection": true,
  "helpfile": "",
  "HTML5CodeInjection": "",
  "html5Props": false,
  "IncludedResources": [],
  "installdir": "",
  "iosCocoaPodDependencies": "",
  "iosCocoaPods": "",
  "ioscodeinjection": "",
  "iosdelegatename": "",
  "iosplistinject": "",
  "iosProps": false,
  "iosSystemFrameworkEntries": [],
  "iosThirdPartyFrameworkEntries": [],
  "license": "",
  "maccompilerflags": "",
  "maclinkerflags": "",
  "macsourcedir": "",
  "name": "FFVideos",
  "options": [],
  "optionsFile": "options.json",
  "packageId": "",
  "parent": {
    "name": "FFVideos",
    "path": "folders/Extensions/FFVideos.yy"
  },
  "productId": "",
  "resourceType": "GMExtension",
  "resourceVersion": "2.0",
  "sourcedir": "",
  "supportedTargets": 72,
  "tvosclassname": "",
  "tvosCocoaPodDependencies": "",
  "tvosCocoaPods": "",
  "tvoscodeinjection": "",
  "tvosdelegatename": "",
  "tvosmaccompilerflags": "",
  "tvosmaclinkerflags": "",
  "tvosplistinject": "",
  "tvosProps": false,
  "tvosSystemFrameworkEntries": [],
  "tvosThirdPartyFrameworkEntries": []
}
