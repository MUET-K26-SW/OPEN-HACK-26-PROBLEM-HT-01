param([int]$Port = 8001)

$ErrorActionPreference = "Stop"
$dataDirectory = Join-Path $env:LOCALAPPDATA "TeamDiamondMedication"
$statePath = Join-Path $dataDirectory "state.json"
$pagePath = Join-Path $PSScriptRoot "index.html"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")

function Send-Response {
    param($Response, [int]$Status, [string]$ContentType, [string]$Body)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Body)
    $Response.StatusCode = $Status
    $Response.ContentType = $ContentType
    $Response.ContentLength64 = $bytes.Length
    $Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $Response.Close()
}

function Send-Json {
    param($Response, [int]$Status, $Value)
    if ($null -eq $Value) {
        Send-Response $Response $Status "application/json; charset=utf-8" "null"
        return
    }
    Send-Response $Response $Status "application/json; charset=utf-8" (ConvertTo-Json -InputObject $Value -Depth 20 -Compress)
}

function Test-MedicationState {
    param($Value)
    if ($null -eq $Value -or $null -eq $Value.meds -or $null -eq $Value.log) { return $false }
    foreach ($medication in @($Value.meds)) {
        if ([string]::IsNullOrWhiteSpace([string]$medication.name) -or $medication.name.Length -gt 200) { return $false }
        if ($null -eq $medication.times) { return $false }
        foreach ($time in @($medication.times)) {
            if ([string]$time -notmatch '^([01]\d|2[0-3]):[0-5]\d$') { return $false }
        }
    }
    if ($null -ne $Value.history) {
        foreach ($entry in @($Value.history)) {
            $entryDate = [string]$entry.date
            $entryTime = [string]$entry.time
            $medicationId = [string]$entry.medicationId
            $medicationName = [string]$entry.medicationName
            $status = [string]$entry.status
            if ($entryDate -notmatch '^\d{4}-\d{1,2}-\d{1,2}$') { return $false }
            if ($entryTime -notmatch '^([01]\d|2[0-3]):[0-5]\d$') { return $false }
            if ([string]::IsNullOrWhiteSpace($medicationId) -or [string]::IsNullOrWhiteSpace($medicationName) -or $medicationName.Length -gt 200) { return $false }
            if ($status -notin @('scheduled', 'taken', 'missed')) { return $false }
        }
    }
    return $true
}

try {
    $listener.Start()
    Write-Host "Team Diamond Medication backend: http://127.0.0.1:$Port"
    Write-Host "Medication data is stored locally at: $statePath"
    Write-Host "Press Ctrl+C to stop."

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $path = $request.Url.AbsolutePath

        try {
            if ($path -eq "/api/health" -and $request.HttpMethod -eq "GET") {
                Send-Json $response 200 @{ status = "ok"; storage = "local" }
                continue
            }

            if ($path -eq "/api/state" -and $request.HttpMethod -eq "GET") {
                if (Test-Path $statePath) {
                    Send-Response $response 200 "application/json; charset=utf-8" ([System.IO.File]::ReadAllText($statePath, [System.Text.Encoding]::UTF8))
                } else {
                    Send-Json $response 200 $null
                }
                continue
            }

            if ($path -eq "/api/state" -and $request.HttpMethod -eq "PUT") {
                if ($request.ContentLength64 -gt 1048576) {
                    Send-Json $response 413 @{ error = "State payload is too large." }
                    continue
                }

                $reader = New-Object System.IO.StreamReader($request.InputStream, [System.Text.Encoding]::UTF8)
                $body = $reader.ReadToEnd()
                $reader.Dispose()
                $value = ConvertFrom-Json -InputObject $body
                if (-not (Test-MedicationState $value)) {
                    Send-Json $response 400 @{ error = "Invalid medication state." }
                    continue
                }

                $storedState = [ordered]@{ meds = @($value.meds); log = $value.log; history = @($value.history) }
                if (-not (Test-Path $dataDirectory)) { New-Item -Path $dataDirectory -ItemType Directory -Force | Out-Null }
                $temporaryPath = "$statePath.$PID.tmp"
                $json = ConvertTo-Json -InputObject $storedState -Depth 20
                [System.IO.File]::WriteAllText($temporaryPath, $json, (New-Object System.Text.UTF8Encoding($false)))
                Move-Item -Path $temporaryPath -Destination $statePath -Force
                Send-Json $response 200 @{ saved = $true }
                continue
            }

            if (($path -eq "/" -or $path -eq "/index.html") -and $request.HttpMethod -eq "GET") {
                $html = [System.IO.File]::ReadAllText($pagePath, [System.Text.Encoding]::UTF8)
                Send-Response $response 200 "text/html; charset=utf-8" $html
                continue
            }

            Send-Json $response 404 @{ error = "Not found." }
        } catch {
            Write-Warning $_.Exception.Message
            try { Send-Json $response 500 @{ error = "Backend request failed." } } catch { }
        }
    }
} finally {
    if ($listener.IsListening) { $listener.Stop() }
    $listener.Close()
}