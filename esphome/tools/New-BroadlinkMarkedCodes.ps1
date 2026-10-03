param(
    [Parameter(Mandatory=$true)][string]$Source,
    [Parameter(Mandatory=$true)][string]$Destination
)
$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath $Destination) { throw 'Destination already exists; preserve it' }
$rfEncoder = Join-Path $PSScriptRoot '../.esphome/decoder-test/broadlink_markers.exe'
if (!(Test-Path -LiteralPath $rfEncoder)) { throw 'Build the native tests/tool with NMAKE first' }
$rfOriginalText = Get-Content -LiteralPath $Source -Raw
$rfOriginal = $rfOriginalText | ConvertFrom-Json
$rfResult = $rfOriginalText | ConvertFrom-Json
$rfReport = @()
foreach ($rfRoom in @('rf.study_fan', 'rf.bedroom_fan')) {
    $rfCommands = @($rfOriginal.data.$rfRoom.PSObject.Properties)
    if ($rfCommands.Count -ne 13) { throw 'Expected exactly 13 commands in each target room' }
    foreach ($rfCommand in $rfCommands) {
        if ($rfCommand.Value -isnot [string]) { throw 'Expected one original code per command' }
        $rfBytes = [Convert]::FromBase64String($rfCommand.Value)
        $rfHex = [Convert]::ToHexString($rfBytes)
        $rfMarkedHex = $rfHex | & $rfEncoder add
        if ($LASTEXITCODE -ne 0) { throw "Native transform failed: $rfRoom / $($rfCommand.Name)" }
        $rfRestoredHex = $rfMarkedHex | & $rfEncoder remove
        if ($LASTEXITCODE -ne 0 -or $rfRestoredHex -ine $rfHex) { throw 'Exact packet restoration failed' }
        $rfMarkedBytes = [Convert]::FromHexString($rfMarkedHex)
        $rfResult.data.$rfRoom.($rfCommand.Name) = [Convert]::ToBase64String($rfMarkedBytes)
        $rfReport += [pscustomobject]@{Room=$rfRoom;Command=$rfCommand.Name;OriginalBytes=$rfBytes.Length;MarkedBytes=$rfMarkedBytes.Length}
    }
}
[IO.File]::WriteAllText([IO.Path]::GetFullPath($Destination), ($rfResult | ConvertTo-Json -Depth 30), [Text.UTF8Encoding]::new($false))
[pscustomobject]@{StagedCommands=$rfReport.Count;ExactRoundTrips=$rfReport.Count;SourceHash=(Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash;DestinationHash=(Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash}
