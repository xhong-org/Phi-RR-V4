{
    "$GMExtension":  "",
    "%Name":  "I_Shaders",
    "androidactivityinject":  "",
    "androidclassname":  "IShaders",
    "androidcodeinjection":  "",
    "androidinject":  "",
    "androidmanifestinject":  "",
    "androidPermissions":  [

                           ],
    "androidProps":  true,
    "androidsourcedir":  "",
    "author":  "PhigrosLoader",
    "classname":  "",
    "copyToTargets":  72,
    "description":  "External shader backend (D3D11 on Windows, GLES on Android).",
    "exportToGame":  true,
    "extensionVersion":  "1.0.0",
    "files":  [
                  {
                      "$GMExtensionFile":  "v1",
                      "%Name":  "I_Shaders.dll",
                      "constants":  [

                                    ],
                      "copyToTargets":  64,
                      "filename":  "I_Shaders.dll",
                      "final":  "rpe_hlsl_shutdown",
                      "functions":  [
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "__rpe_hlsl_initialize",
                                            "argCount":  2,
                                            "args":  [
                                                         1,
                                                         2
                                                     ],
                                            "documentation":  "@param {Pointer} _arg_buffer\r\n@param {Real} _arg_buffer_length\r\n@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_initialize",
                                            "help":  "",
                                            "hidden":  true,
                                            "kind":  4,
                                            "name":  "__rpe_hlsl_initialize",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_hlsl_state",
                                            "argCount":  0,
                                            "args":  [

                                                     ],
                                            "documentation":  "@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_state",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_hlsl_state",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_hlsl_compile",
                                            "argCount":  2,
                                            "args":  [
                                                         1,
                                                         1
                                                     ],
                                            "documentation":  "@param {String} source\r\n@param {String} source_name\r\n@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_compile",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_hlsl_compile",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_glsl_translate",
                                            "argCount":  2,
                                            "args":  [
                                                         1,
                                                         1
                                                     ],
                                            "documentation":  "@param {String} source\r\n@param {String} source_name\r\n@returns {String}",
                                            "externalName":  "__EXT_NATIVE__rpe_glsl_translate",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_glsl_translate",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  1
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_hlsl_set_uniform_component",
                                            "argCount":  4,
                                            "args":  [
                                                         2,
                                                         1,
                                                         2,
                                                         2
                                                     ],
                                            "documentation":  "@param {Real} handle\r\n@param {String} uniform_name\r\n@param {Real} component\r\n@param {Real} value\r\n@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_set_uniform_component",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_hlsl_set_uniform_component",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_hlsl_begin",
                                            "argCount":  1,
                                            "args":  [
                                                         2
                                                     ],
                                            "documentation":  "@param {Real} handle\r\n@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_begin",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_hlsl_begin",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_hlsl_draw",
                                            "argCount":  5,
                                            "args":  [
                                                         2,
                                                         2,
                                                         2,
                                                         2,
                                                         2
                                                     ],
                                            "documentation":  "@param {Real} handle\r\n@param {Real} uv_left\r\n@param {Real} uv_top\r\n@param {Real} uv_right\r\n@param {Real} uv_bottom\r\n@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_draw",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_hlsl_draw",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_hlsl_target_width",
                                            "argCount":  0,
                                            "args":  [

                                                     ],
                                            "documentation":  "@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_target_width",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_hlsl_target_width",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_hlsl_target_height",
                                            "argCount":  0,
                                            "args":  [

                                                     ],
                                            "documentation":  "@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_target_height",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_hlsl_target_height",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_hlsl_end",
                                            "argCount":  0,
                                            "args":  [

                                                     ],
                                            "documentation":  "@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_end",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_hlsl_end",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_hlsl_release",
                                            "argCount":  1,
                                            "args":  [
                                                         2
                                                     ],
                                            "documentation":  "@param {Real} handle\r\n@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_release",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_hlsl_release",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_hlsl_shutdown",
                                            "argCount":  0,
                                            "args":  [

                                                     ],
                                            "documentation":  "@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_shutdown",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_hlsl_shutdown",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_hlsl_get_error",
                                            "argCount":  0,
                                            "args":  [

                                                     ],
                                            "documentation":  "@returns {String}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_get_error",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_hlsl_get_error",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  1
                                        }
                                    ],
                      "init":  "",
                      "kind":  1,
                      "name":  "I_Shaders.dll",
                      "origname":  "",
                      "ProxyFiles":  [

                                     ],
                      "resourceType":  "GMExtensionFile",
                      "resourceVersion":  "2.0",
                      "uncompress":  false,
                      "usesRunnerInterface":  false
                  },
                  {
                      "$GMExtensionFile":  "v1",
                      "%Name":  "IShaders.ext",
                      "constants":  [

                                    ],
                      "copyToTargets":  8,
                      "filename":  "IShaders.ext",
                      "final":  "rpe_gles_shutdown",
                      "functions":  [
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "__rpe_gles_initialize",
                                            "argCount":  2,
                                            "args":  [
                                                         1,
                                                         2
                                                     ],
                                            "documentation":  "@param {Pointer} _arg_buffer\r\n@param {Real} _arg_buffer_length\r\n@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_initialize",
                                            "help":  "",
                                            "hidden":  true,
                                            "kind":  4,
                                            "name":  "__rpe_gles_initialize",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_gles_state",
                                            "argCount":  0,
                                            "args":  [

                                                     ],
                                            "documentation":  "@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_state",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_gles_state",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_gles_compile",
                                            "argCount":  2,
                                            "args":  [
                                                         1,
                                                         1
                                                     ],
                                            "documentation":  "@param {String} source\r\n@param {String} source_name\r\n@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_compile",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_gles_compile",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_gles_translate",
                                            "argCount":  2,
                                            "args":  [
                                                         1,
                                                         1
                                                     ],
                                            "documentation":  "@param {String} source\r\n@param {String} source_name\r\n@returns {String}",
                                            "externalName":  "__EXT_NATIVE__rpe_glsl_translate",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_gles_translate",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  1
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_gles_set_uniform_component",
                                            "argCount":  4,
                                            "args":  [
                                                         2,
                                                         1,
                                                         2,
                                                         2
                                                     ],
                                            "documentation":  "@param {Real} handle\r\n@param {String} uniform_name\r\n@param {Real} component\r\n@param {Real} value\r\n@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_set_uniform_component",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_gles_set_uniform_component",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_gles_begin",
                                            "argCount":  1,
                                            "args":  [
                                                         2
                                                     ],
                                            "documentation":  "@param {Real} handle\r\n@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_begin",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_gles_begin",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_gles_draw",
                                            "argCount":  5,
                                            "args":  [
                                                         2,
                                                         2,
                                                         2,
                                                         2,
                                                         2
                                                     ],
                                            "documentation":  "@param {Real} handle\r\n@param {Real} uv_left\r\n@param {Real} uv_top\r\n@param {Real} uv_right\r\n@param {Real} uv_bottom\r\n@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_draw",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_gles_draw",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_gles_target_width",
                                            "argCount":  0,
                                            "args":  [

                                                     ],
                                            "documentation":  "@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_target_width",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_gles_target_width",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_gles_target_height",
                                            "argCount":  0,
                                            "args":  [

                                                     ],
                                            "documentation":  "@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_target_height",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_gles_target_height",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_gles_end",
                                            "argCount":  0,
                                            "args":  [

                                                     ],
                                            "documentation":  "@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_end",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_gles_end",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_gles_release",
                                            "argCount":  1,
                                            "args":  [
                                                         2
                                                     ],
                                            "documentation":  "@param {Real} handle\r\n@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_release",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_gles_release",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_gles_shutdown",
                                            "argCount":  0,
                                            "args":  [

                                                     ],
                                            "documentation":  "@returns {Real}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_shutdown",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_gles_shutdown",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  2
                                        },
                                        {
                                            "$GMExtensionFunction":  "",
                                            "%Name":  "rpe_gles_get_error",
                                            "argCount":  0,
                                            "args":  [

                                                     ],
                                            "documentation":  "@returns {String}",
                                            "externalName":  "__EXT_NATIVE__rpe_hlsl_get_error",
                                            "help":  "",
                                            "hidden":  false,
                                            "kind":  4,
                                            "name":  "rpe_gles_get_error",
                                            "resourceType":  "GMExtensionFunction",
                                            "resourceVersion":  "2.0",
                                            "returnType":  1
                                        }
                                    ],
                      "init":  "",
                      "kind":  4,
                      "name":  "IShaders.ext",
                      "origname":  "",
                      "ProxyFiles":  [

                                     ],
                      "resourceType":  "GMExtensionFile",
                      "resourceVersion":  "2.0",
                      "uncompress":  false,
                      "usesRunnerInterface":  false
                  }
              ],
    "gradleinject":  "",
    "hasConvertedCodeInjection":  true,
    "helpfile":  "",
    "HTML5CodeInjection":  "",
    "html5Props":  false,
    "IncludedResources":  [

                          ],
    "installdir":  "",
    "iosCocoaPodDependencies":  "",
    "iosCocoaPods":  "",
    "ioscodeinjection":  "",
    "iosdelegatename":  "",
    "iosplistinject":  "",
    "iosProps":  false,
    "iosSystemFrameworkEntries":  [

                                  ],
    "iosThirdPartyFrameworkEntries":  [

                                      ],
    "license":  "",
    "maccompilerflags":  "",
    "maclinkerflags":  "",
    "macsourcedir":  "",
    "name":  "I_Shaders",
    "options":  [

                ],
    "optionsFile":  "options.json",
    "packageId":  "",
    "parent":  {
                   "name":  "I_Shaders",
                   "path":  "folders/Extensions/I_Shaders.yy"
               },
    "productId":  "",
    "resourceType":  "GMExtension",
    "resourceVersion":  "2.0",
    "sourcedir":  "",
    "supportedTargets":  72,
    "tvosclassname":  "",
    "tvosCocoaPodDependencies":  "",
    "tvosCocoaPods":  "",
    "tvoscodeinjection":  "",
    "tvosdelegatename":  "",
    "tvosmaccompilerflags":  "",
    "tvosmaclinkerflags":  "",
    "tvosplistinject":  "",
    "tvosProps":  false,
    "tvosSystemFrameworkEntries":  [

                                   ],
    "tvosThirdPartyFrameworkEntries":  [

                                       ]
}
