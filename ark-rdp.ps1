# ark-rdp.ps1 - Wrapper to fetch and auto-open an RDP file via ark-cli
#
# Usage: .\ark-rdp.ps1 -TargetHost <target_host>
#
# Will interactively prompt for connection type (ZSP, Standing, or Privilege
# Elevation) and, if Standing or Privilege Elevation, for username and domain.

param(
    [Parameter(Mandatory = $true)]
    [string]$TargetHost
)

# -- Configuration (edit before use) ------------------------------------------
$ProfileName   = ""
$DefaultUser   = ""
$DefaultDomain = ""
$OutputDir     = ""

# -- Prompt for profile name ---------------------------------------------------
Write-Host ""
$InputProfile = Read-Host "Profile name [$ProfileName]"
if ($InputProfile) { $ProfileName = $InputProfile }

# -- Prompt for connection type ------------------------------------------------
Write-Host ""
Write-Host "Connection type:"
Write-Host "  1) ZSP                 (no credentials required)"
Write-Host "  2) Standing            (username + domain required)"
Write-Host "  3) Privilege Elevation (username + domain required)"
Write-Host ""
$ConnType = Read-Host "Select [1/2/3]"

switch ($ConnType) {
    "1" { $ConnMode = "zsp" }
    "2" { $ConnMode = "standing" }
    "3" { $ConnMode = "elevation" }
    default {
        Write-Error "Error: invalid selection."
        exit 1
    }
}

# -- Prompt for credentials if Standing or Privilege Elevation -----------------
if ($ConnMode -eq "standing" -or $ConnMode -eq "elevation") {
    $InputUser = Read-Host "Username [$DefaultUser]"
    $RdpUser   = if ($InputUser) { $InputUser } else { $DefaultUser }

    $InputDomain = Read-Host "Domain [$DefaultDomain]"
    $RdpDomain   = if ($InputDomain) { $InputDomain } else { $DefaultDomain }
}

# -- Validate configuration ----------------------------------------------------
if (-not $OutputDir) {
    Write-Error "Error: `$OutputDir is not set. Edit the configuration and set it before use."
    exit 1
}

# -- Ensure output directory exists --------------------------------------------
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# -- Run ark -------------------------------------------------------------------
Write-Host ""
Write-Host "Fetching RDP file for $TargetHost..."

switch ($ConnMode) {
    "zsp" {
        ark exec -ra -pn $ProfileName sia sso short-lived-rdp-file `
            -ta $TargetHost `
            -f $OutputDir
    }
    "standing" {
        ark exec -ra -pn $ProfileName sia sso short-lived-rdp-file `
            -ta $TargetHost `
            -tu $RdpUser `
            -td $RdpDomain `
            -f $OutputDir
    }
    "elevation" {
        ark exec -ra -pn $ProfileName sia sso short-lived-rdp-file `
            -ta $TargetHost `
            -tu $RdpUser `
            -td $RdpDomain `
            -ep `
            -f $OutputDir
    }
}

# -- Open the most recently created file in the output directory ---------------
$Latest = Get-ChildItem -Path $OutputDir | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $Latest) {
    Write-Error "Error: No files found in $OutputDir after ark exec."
    exit 1
}

Write-Host "Opening $($Latest.FullName)"
Invoke-Item $Latest.FullName