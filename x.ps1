# GitHub repository information
$repoOwner = "jelpsIT"
$repoName = "HWID_Intune"

# Personal Access Token (PAT) for GitHub authentication
$pat = "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"

# Generate CSV file using Get-WindowsAutoPilotInfo
$scriptDir = "C:\HWID"
New-Item -Type Directory -Path $scriptDir -Force | Out-Null
Set-Location -Path $scriptDir
$env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Install-Script -Name Get-WindowsAutoPilotInfo
Get-WindowsAutoPilotInfo -OutputFile AutoPilotHWID.csv

# Find the device name
$deviceName = $env:COMPUTERNAME

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser

# Rename CSV file using the device name, overwriting if it already exists
$csvPath = Join-Path -Path $scriptDir -ChildPath "$deviceName.csv"

# Check if the file already exists and delete it
if (Test-Path -Path $csvPath) {
    Remove-Item -Path $csvPath -Force
}

Rename-Item -Path "AutoPilotHWID.csv" -NewName $deviceName

# GitHub repository details
$githubRepoUrl = "https://github.com/$repoOwner/$repoName.git"

# GitHub API URL for uploading a file
$uploadUrl = "https://api.github.com/repos/$repoOwner/$repoName/contents/$deviceName.csv"

# Convert the CSV file to Base64
$fileContentBase64 = [Convert]::ToBase64String((Get-Content -Path $deviceName -Encoding Byte))

# Create a JSON payload for GitHub API
$payload = @{
    message   = "Upload $deviceName.csv"
    content   = $fileContentBase64
    branch    = "main"
} | ConvertTo-Json

# Upload the file to GitHub using GitHub API
Invoke-RestMethod -Uri $uploadUrl -Headers @{
    Authorization = "Bearer $pat"
    Accept        = "application/vnd.github.v3+json"
} -Method Put -Body $payload
