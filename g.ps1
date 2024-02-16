# GitHub repository information
$repoOwner = "jelpsIT"
$repoName = "HWID_Intune"

# GitHub Personal Access Token
$kda = "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"

# Generate CSV file using Get-WindowsAutoPilotInfo
$scriptDir = "C:\HWID"
New-Item -Type Directory -Path $scriptDir -Force | Out-Null
Set-Location -Path $scriptDir
$env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Install-Script -Name Get-WindowsAutoPilotInfo -Force
Get-WindowsAutoPilotInfo -OutputFile AutoPilotHWID.csv

# Find the device name
$deviceName = $env:COMPUTERNAME

# Set environment variable to skip NuGet provider check
$env:POWERSHELL_PACKAGE_MANAGEMENT_SKIP_PROVIDER_CHECK = $true

# Install NuGet provider without confirmation
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
Start-Sleep -Seconds 2

# Install NuGet provider without confirmation
Install-PackageProvider -Name NuGet -Force -Scope CurrentUser

# Clear the environment variable
Remove-Item Env:\POWERSHELL_PACKAGE_MANAGEMENT_SKIP_PROVIDER_CHECK

# Check if the file already exists with the new name
$newCsvPath = Join-Path -Path $scriptDir -ChildPath "$deviceName.csv"

# Check if the file to be renamed exists
if (Test-Path -Path "AutoPilotHWID.csv") {
    try {
        # Attempt to rename CSV file using the device name, overwriting if it already exists
        Move-Item -Path "AutoPilotHWID.csv" -Destination "$deviceName.csv" -Force -ErrorAction Stop

        # Success message
        Write-Host "File successfully renamed to $deviceName.csv"
    } catch {
        # Display error message if renaming fails
        Write-Host "Error renaming the file: $_"
    }
} else {
    # Display message if the file to be renamed does not exist
    Write-Host "The file 'AutoPilotHWID.csv' does not exist."
}


# GitHub repository details
$githubRepoUrl = "https://github.com/$repoOwner/$repoName.git"

# GitHub API URL for uploading a file
$uploadUrl = "https://api.github.com/repos/$repoOwner/$repoName/contents/$deviceName.csv"

# Convert the CSV file to Base64
$fileContent = Get-Content -Path "$deviceName.csv" -Raw
$fileContentBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($fileContent))

# Calculate SHA-1 hash of the current file content
$sha1 = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider
$hashBytes = $sha1.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($fileContent))
$currentFileSha = [BitConverter]::ToString($hashBytes) -replace '-'

# Check if the calculated SHA-1 hash matches the existing one
if ($currentFileSha -eq $existingFileSha.ToLower()) {
    # Create a JSON payload for GitHub API
    $payload = @{
        message   = "Upload $deviceName.csv"
        content   = $fileContentBase64
        branch    = "main"
        sha       = $currentFileSha.ToLower()  # Use the updated SHA-1 hash
    } | ConvertTo-Json

    # Upload the file to GitHub using GitHub API
    try {
        Invoke-RestMethod -Uri $uploadUrl -Headers @{
            Authorization = "Bearer $kda"
            Accept        = "application/vnd.github.v3+json"
        } -Method Put -Body $payload

        Write-Host "File uploaded to GitHub successfully."
    } catch {
        Write-Host "Error uploading the file to GitHub: $_"
    }
} else {
    Write-Host "Error: The file content has been modified. Calculated SHA-1 hash does not match the existing one."
}

