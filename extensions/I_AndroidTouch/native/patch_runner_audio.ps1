param([string]$Library)

$ErrorActionPreference = 'Stop'

# Runtime 2026.0.0.23 shares one condition variable between SuspendAll and
# CheckSuspend. The final worker's notify_one can wake a peer instead of the
# UI thread; all five threads then sleep forever. Broadcast preserves both
# predicates and the original pause/resume protocol.
#
# Patch only the generated ARM64 library, never the installed Runtime. VM and
# YYC relocate this function differently, so find symbols via ELF and verify
# the entire function with BL immediates masked before changing one call.
if (!$Library) {
    $package = @($env:YYPLATFORM_option_android_package_domain,
        $env:YYPLATFORM_option_android_package_company,
        $env:YYPLATFORM_option_android_package_product) -join '.'
    $buildRoot = Split-Path -Parent $env:YYoutputFolder
    $Library = Join-Path $buildRoot "android/Default/$package/src/main/jniLibs/arm64-v8a/libyoyo.so"
}

$image = [IO.File]::ReadAllBytes($Library)
if ([BitConverter]::ToUInt32($image, 0) -ne 0x464c457f -or
    $image[4] -ne 2 -or $image[5] -ne 1 -or
    [BitConverter]::ToUInt16($image, 18) -ne 183) {
    throw '[AndroidAudio] Expected a little-endian ARM64 ELF library.'
}

$sections = @()
$table = [BitConverter]::ToInt64($image, 40)
$entrySize = [BitConverter]::ToUInt16($image, 58)
$entryCount = [BitConverter]::ToUInt16($image, 60)
for ($i = 0; $i -lt $entryCount; $i++) {
    $offset = $table + $i * $entrySize
    $sections += [pscustomobject]@{
        Type = [BitConverter]::ToUInt32($image, $offset + 4)
        Address = [BitConverter]::ToInt64($image, $offset + 16)
        Offset = [BitConverter]::ToInt64($image, $offset + 24)
        Size = [BitConverter]::ToInt64($image, $offset + 32)
        Link = [BitConverter]::ToUInt32($image, $offset + 40)
        EntrySize = [BitConverter]::ToInt64($image, $offset + 56)
    }
}

$names = @(
    '_ZN14DecodingThread12CheckSuspendEv',
    '_ZNSt6__ndk118condition_variable10notify_oneEv',
    '_ZNSt6__ndk118condition_variable10notify_allEv'
)
$symbols = @{}
$dynamic = $sections | Where-Object Type -eq 11 | Select-Object -First 1
if ($dynamic) {
    $strings = $sections[$dynamic.Link]
    for ($i = 0; $i -lt $dynamic.Size / $dynamic.EntrySize; $i++) {
        $offset = $dynamic.Offset + $i * $dynamic.EntrySize
        $start = $strings.Offset + [BitConverter]::ToUInt32($image, $offset)
        $end = $start
        while ($image[$end] -ne 0) { $end++ }
        $name = [Text.Encoding]::ASCII.GetString($image, $start, $end - $start)
        if ($names -notcontains $name) { continue }
        $symbols[$name] = [pscustomobject]@{
            Index = $i
            Section = [BitConverter]::ToUInt16($image, $offset + 6)
            Address = [BitConverter]::ToInt64($image, $offset + 8)
            Size = [BitConverter]::ToInt64($image, $offset + 16)
        }
    }
}

if ($symbols.Count -ne 3 -or $symbols[$names[0]].Size -ne 296) {
    Write-Host '[AndroidAudio] Different Runtime layout; audio pause fix not applied.'
    exit 0
}

$check = $symbols[$names[0]]
$section = $sections[$check.Section]
$functionOffset = $section.Offset + $check.Address - $section.Address
$normalized = New-Object byte[] $check.Size
[Array]::Copy($image, $functionOffset, $normalized, 0, $check.Size)
for ($i = 0; $i -lt $normalized.Length; $i += 4) {
    $instruction = [BitConverter]::ToUInt32($normalized, $i)
    if (($instruction -band 0xfc000000L) -eq 0x94000000L) {
        [BitConverter]::GetBytes([uint32]0x94000000L).CopyTo($normalized, $i)
    }
}
$sha = [Security.Cryptography.SHA256]::Create()
try {
    $digest = ([BitConverter]::ToString($sha.ComputeHash($normalized))).Replace('-', '').ToLowerInvariant()
} finally { $sha.Dispose() }
if ($digest -ne 'cbedc5f633b99b93957f5d322378d3bb5dbef73ecc53c506e6de7b6a3e89001f') {
    Write-Host '[AndroidAudio] Different CheckSuspend implementation; audio pause fix not applied.'
    exit 0
}

# The verified function calls notify_one at +0x90. Accept a direct call or
# a PLT entry whose ELF relocation names that exact symbol; reject any other
# target. This also makes repeated packaging of an already fixed copy safe.
$callOffset = $functionOffset + 0x90
$callAddress = $check.Address + 0x90
$instruction = [BitConverter]::ToUInt32($image, $callOffset)
$distance = [long]($instruction -band 0x03ffffffL)
if (($distance -band 0x02000000L) -ne 0) { $distance -= 0x04000000L }
$target = $callAddress + $distance * 4
$broadcast = $symbols[$names[2]].Address
if ($target -eq $broadcast) {
    Write-Host '[AndroidAudio] Audio pause broadcast already applied.'
    exit 0
}

$isNotifyOne = $target -eq $symbols[$names[1]].Address
if (!$isNotifyOne) {
    $plt = $sections | Where-Object { $_.Type -eq 1 -and
        $target -ge $_.Address -and $target + 16 -le $_.Address + $_.Size } | Select-Object -First 1
    if ($plt) {
        $offset = $plt.Offset + $target - $plt.Address
        $adrp = [BitConverter]::ToUInt32($image, $offset)
        $ldr = [BitConverter]::ToUInt32($image, $offset + 4)
        $br = [BitConverter]::ToUInt32($image, $offset + 12)
        if (($adrp -band 0x9f00001fL) -eq 0x90000010L -and
            ($ldr -band 0xffc003ffL) -eq 0xf9400211L -and $br -eq 0xd61f0220L) {
            $pageDelta = (($adrp -shr 5 -band 0x7ffffL) -shl 2) -bor ($adrp -shr 29 -band 3)
            if (($pageDelta -band 0x100000L) -ne 0) { $pageDelta -= 0x200000L }
            $got = ($target -band -4096L) + $pageDelta * 4096 + ($ldr -shr 10 -band 0xfffL) * 8
            foreach ($relocations in ($sections | Where-Object Type -eq 4)) {
                for ($i = $relocations.Offset; $i -lt $relocations.Offset + $relocations.Size; $i += $relocations.EntrySize) {
                    if ([BitConverter]::ToInt64($image, $i) -ne $got) { continue }
                    $info = [BitConverter]::ToUInt64($image, $i + 8)
                    $isNotifyOne = ($info -shr 32) -eq $symbols[$names[1]].Index -and
                        ($info -band 0xffffffffL) -eq 1026
                    break
                }
            }
        }
    }
}
if (!$isNotifyOne) { throw '[AndroidAudio] Unexpected notify_one target; library left unchanged.' }

$distance = $broadcast - $callAddress
if ($distance % 4 -ne 0 -or $distance -lt -134217728 -or $distance -ge 134217728) {
    throw '[AndroidAudio] Broadcast target is outside the ARM64 BL range.'
}
$replacement = [uint32](0x94000000L -bor (($distance / 4) -band 0x03ffffffL))
[BitConverter]::GetBytes($replacement).CopyTo($image, $callOffset)
[IO.File]::WriteAllBytes($Library, $image)
Write-Host '[AndroidAudio] Fixed audio pause wake-up (notify_one -> notify_all).'
