# Add Google Cloud SDK bin to PATH permanently.
# Usage:
#   User (default):  powershell -ExecutionPolicy Bypass -File add-gcloud-path.ps1
#   System (Machine): Run PowerShell as Administrator, then:
#                     powershell -ExecutionPolicy Bypass -File add-gcloud-path.ps1 -Machine

param([switch]$Machine)
$gcloudBin = "C:\Users\ASUS\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin"
$target = if ($Machine) { "Machine" } else { "User" }

$current = [Environment]::GetEnvironmentVariable("Path", $target)
if ($current -and $current -notlike "*$gcloudBin*") {
    [Environment]::SetEnvironmentVariable("Path", $current.TrimEnd(";") + ";" + $gcloudBin, $target)
    Write-Host "Added gcloud to $target PATH: $gcloudBin"
} elseif ($current -and $current -like "*$gcloudBin*") {
    Write-Host "gcloud path already in $target PATH."
} else {
    [Environment]::SetEnvironmentVariable("Path", $gcloudBin, $target)
    Write-Host "Set $target PATH to: $gcloudBin"
}
Write-Host "Close and reopen your terminal (and Cursor) for PATH to take effect."
