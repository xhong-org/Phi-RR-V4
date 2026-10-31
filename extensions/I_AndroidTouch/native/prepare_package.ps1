$ErrorActionPreference = 'Stop'

$package = @($env:YYPLATFORM_option_android_package_domain,
    $env:YYPLATFORM_option_android_package_company,
    $env:YYPLATFORM_option_android_package_product) -join '.'
$buildRoot = Split-Path -Parent $env:YYoutputFolder
$project = Join-Path $buildRoot "android/Default/$package"

# R8 cannot see JNI FindClass/GetMethodID calls. Keep FMOD and the generated
# native bridges by their real package names, including native callbacks.
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'android-keep.pro') -Destination $project

# Extensions can copy libraries for disabled ABIs after GameMaker has already
# filtered its own Runtime. Filter at packaging time without deleting sources.
$abis = @()
if ($env:YYPLATFORM_option_android_arch_arm64 -eq 'True') { $abis += 'arm64-v8a' }
if ($env:YYPLATFORM_option_android_arch_armv7 -eq 'True') { $abis += 'armeabi-v7a' }
if ($env:YYPLATFORM_option_android_arch_x86_64 -eq 'True') { $abis += 'x86_64' }
if (!$abis.Count) { throw '[AndroidPackage] No Android ABI is enabled.' }
$filters = ($abis | ForEach-Object { "'$_'" }) -join ', '
$gradle = Join-Path $project 'build.gradle'
$marker = '// Phi-RR Android packaging'
$text = [IO.File]::ReadAllText($gradle)
if (!$text.Contains($marker)) {
    $text += @"

$marker
android {
    defaultConfig { ndk { abiFilters $filters } }
    buildTypes.release { proguardFiles 'android-keep.pro' }
}
"@
    [IO.File]::WriteAllText($gradle, $text, (New-Object Text.UTF8Encoding $false))
}

# Use the configured NDK, not a hard-coded SDK install. Only strip generated
# extension copies; the repository's libraries remain usable for debugging.
$ndkPaths = @(Get-ChildItem Env: | Where-Object Name -Match 'ndk' | ForEach-Object Value)
$options = Join-Path $PSScriptRoot '../../../gm-options.json'
if (Test-Path -LiteralPath $options) {
    $config = [IO.File]::ReadAllText($options) | ConvertFrom-Json
    if ($config.gms2.android.ndkPath) { $ndkPaths += $config.gms2.android.ndkPath }
}
$strip = $null
foreach ($ndk in $ndkPaths) {
    if (!$ndk) { continue }
    $candidate = Join-Path $ndk 'toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-strip.exe'
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { $strip = $candidate; break }
}
if (!$strip) { throw '[AndroidPackage] Cannot find llvm-strip in the configured Android NDK.' }

$saved = 0L
foreach ($abi in $abis) {
    foreach ($root in @('elibs', 'src/main/jniLibs')) {
        $folder = Join-Path $project "$root/$abi"
        if (!(Test-Path -LiteralPath $folder)) { continue }
        foreach ($library in (Get-ChildItem -LiteralPath $folder -Filter '*.so' -File)) {
            # The Runtime is already stripped; leave the audio compatibility fix intact.
            if ($library.Name -eq 'libyoyo.so') { continue }
            $before = $library.Length
            & $strip --strip-unneeded $library.FullName
            if ($LASTEXITCODE -ne 0) { throw "[AndroidPackage] Failed to strip $($library.Name)." }
            $saved += $before - (Get-Item -LiteralPath $library.FullName).Length
        }
    }
}
Write-Host ("[AndroidPackage] ABIs: {0}; removed {1:N2} MiB of native debug data." -f ($abis -join ', '), ($saved / 1MB))
