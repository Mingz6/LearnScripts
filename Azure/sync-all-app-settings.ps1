# Azure Function Apps Settings Synchronizer
# This script retrieves app settings from Azure for all Function Apps and resolves KeyVault references
param (
    [string]$DbPassword = "TheSuperSafePassword123" # Default password for the database connection string
)

# Function to write colored output (supports both Windows and macOS)
function Write-ColorOutput {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Color = "White"
    )
    
    $originalColor = $host.UI.RawUI.ForegroundColor
    
    try {
        $host.UI.RawUI.ForegroundColor = $Color
        Write-Output $Message
    }
    finally {
        $host.UI.RawUI.ForegroundColor = $originalColor
    }
}

# Configuration
$ResourceGroup = "<rg-name>"
$KeyVaultName = "<kv-name>"
$OutputDir = Join-Path (Get-Location) "dotnet"
$LocalSettingsFilename = "local.settings.json"

# Hardcoded settings that will always be applied to every function app
$HardcodedSettings = @{
    "APPINSIGHTS_INSTRUMENTATIONKEY" = "UseDevelopmentStorage=true"
    "AzureWebJobsStorage" = "UseDevelopmentStorage=true"
}

# Database connection string with parameterized password
$DbConnectionString = "server=localhost;database=<DbName>;user id=sa;password=$DbPassword;Encrypt=True;TrustServerCertificate=True;MultipleActiveResultSets=True;"

# List of all function apps to process - Format: @("func-name:module-dir:project-name-pattern")
$FunctionApps = @(
    "func-appname-dev:Domain:Name1"
    "func-appname-dev:Domain:Name2"
)

# Detect OS 
$global:IsWindowsOS = $PSVersionTable.Platform -eq 'Win32NT' -or (-not (Get-Variable -Name 'PSVersionTable' -ErrorAction SilentlyContinue) -or -not (Get-Variable -Name 'IsLinux' -ErrorAction SilentlyContinue))
$global:IsMacOSX = $PSVersionTable.Platform -eq 'Unix' -and [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)

# Check if AZ Cli is installed
function Test-AzureCliInstallation {
    try {
        $azCliInstalled = $null -ne (Get-Command az -ErrorAction SilentlyContinue)
        
        if (-not $azCliInstalled) {
            Write-ColorOutput "Error: Azure CLI is not installed. Please install it first." "Red"
            
            if ($global:IsMacOSX) {
                Write-Output "You can install it using: brew install azure-cli"
            }
            elseif ($global:IsWindowsOS) {
                Write-Output "You can install it from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows"
            }
            return $false
        }
        
        return $true
    }
    catch {
        Write-ColorOutput "Error checking Azure CLI installation: $_" "Red"
        return $false
    }
}

# Function to check Azure login status
function Test-AzureLogin {
    Write-ColorOutput "Checking Azure CLI login status..." "Cyan"
    
    try {
        # Try to get the current account
        $accountInfo = az account show 2>$null | ConvertFrom-Json
        
        if ($null -eq $accountInfo) {
            Write-ColorOutput "You are not logged in to Azure. Please login." "Yellow"
            az login
            
            if ($LASTEXITCODE -ne 0) {
                Write-ColorOutput "Failed to login to Azure. Exiting." "Red"
                return $false
            }
            
            $accountInfo = az account show | ConvertFrom-Json
        }
        
        # Display current account info
        Write-ColorOutput "Logged in to Azure as $($accountInfo.user.name) in subscription $($accountInfo.name)" "Green"
        return $true
    }
    catch {
        Write-ColorOutput "Error checking Azure login: $_" "Red"
        return $false
    }
}

# Function to check KeyVault access
function Test-KeyVaultAccess {
    param (
        [string]$KeyVaultName
    )
    
    Write-ColorOutput "Checking access to KeyVault $KeyVaultName..." "Cyan"
    
    try {
        # Check if the KeyVault exists and we have access
        $keyVaultExists = $null -ne (az keyvault show --name "$KeyVaultName" 2>$null | ConvertFrom-Json)
        
        if (-not $keyVaultExists) {
            Write-ColorOutput "Warning: Cannot access KeyVault $KeyVaultName. Secret values will remain as placeholders." "Yellow"
            Write-ColorOutput "Make sure you have 'Key Vault Secrets User' or 'Key Vault Reader' role assigned." "Yellow"
            return $false
        }
        
        # Also explicitly check if we can list secrets
        $canListSecrets = $null -ne (az keyvault secret list --vault-name "$KeyVaultName" --query "[].id" 2>$null | ConvertFrom-Json)
        
        if (-not $canListSecrets) {
            Write-ColorOutput "Warning: You have access to KeyVault but not to secrets. Secret values will remain as placeholders." "Yellow"
            Write-ColorOutput "Make sure you have 'Key Vault Secrets User' or 'Key Vault Reader' role assigned." "Yellow"
            return $false
        }
        
        Write-ColorOutput "Successfully accessed KeyVault $KeyVaultName with secret listing permissions" "Green"
        return $true
    }
    catch {
        Write-ColorOutput "Error checking KeyVault access: $_" "Red"
        return $false
    }
}

# Function to get a secret from KeyVault
function Get-KeyVaultSecret {
    param (
        [string]$SecretName,
        [string]$KeyVaultName
    )
    
    try {
        # Remove any trailing parenthesis in the secret name
        $cleanSecretName = $SecretName -replace "\)$", ""
        
        # Try to get the secret value
        $secretValue = az keyvault secret show --vault-name "$KeyVaultName" --name "$cleanSecretName" --query "value" -o tsv 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "Warning: Could not retrieve secret '$cleanSecretName' from KeyVault." "Yellow"
            return "KEY_VAULT_VALUE_FOR_$cleanSecretName"
        }
        
        return $secretValue
    }
    catch {
        Write-ColorOutput "Error retrieving secret: $_" "Red"
        return "KEY_VAULT_VALUE_FOR_$cleanSecretName"
    }
}

# Function to determine the target directory for a function app
function Get-FunctionAppDirectory {
    param (
        [string]$AppName,
        [string]$ModuleName,
        [string]$ProjectPattern
    )
    
    # Extract the function app short name from the full name
    $appShortName = ($AppName -split '-')[4]
    
    # Try with capitalized first letter
    $appDirName = $appShortName.Substring(0, 1).ToUpper() + $appShortName.Substring(1)
    
    # Special case for "document" -> "DocumentManagement"
    if ($appShortName -eq "document") {
        $appDirName = "DocumentManagement"
    }
    
    # Define potential namespaces based on the project pattern and app name
    $namespaces = @()
    
    if ($ProjectPattern -eq "DOMAIN1") {
        $namespaces += "DOMAIN.FuncApps.$appShortName", "DOMAIN1.FuncApps.$appDirName"
    }
    elseif ($ProjectPattern -like "Enterprise*") {
        # Check if the pattern contains the full namespace
        if ($ProjectPattern -like "*.*") {
            $namespaces += "$ProjectPattern", "Enterprise.FuncApps.$appDirName"
        }
        else {
            $namespaces += "Enterprise.FuncApps.$appShortName", "Enterprise.FuncApps.$appDirName"
        }
    }
    elseif ($ProjectPattern -eq "DOMAIN2") {
        $namespaces += "DOMAIN2.FuncApps.$appDirName", "DOMAIN2.FuncApps.$appShortName"
    }
    else {
        # Fallback to try all common patterns
        $namespaces += "DOMAIN1.FuncApps.$appShortName", "Enterprise.FuncApps.$appShortName", "DOMAIN2.FuncApps.$appShortName"
        $namespaces += "DOMAIN1.FuncApps.$appDirName", "Enterprise.FuncApps.$appDirName", "DOMAIN2.FuncApps.$appDirName"
        
        # Special case for document management
        if ($appShortName -eq "document") {
            $namespaces += "Enterprise.FuncApps.DocumentManagement.Staging", "Enterprise.FuncApps.DocumentManagement"
        }
    }
    
    # Try to find the actual namespace + directory structure by checking multiple possibilities
    foreach ($namespace in $namespaces) {
        $dirPath = Join-Path $OutputDir $ModuleName $namespace
        
        if (Test-Path $dirPath -PathType Container) {
            return $dirPath
        }
    }
    
    # If we don't find the namespace+directory directly, search more broadly in the module
    $foundDir = Get-ChildItem -Path (Join-Path $OutputDir $ModuleName) -Directory -Filter "*FuncApps*" | Select-Object -First 1 -ExpandProperty FullName
    
    if ($foundDir) {
        return $foundDir
    }
    
    # If not found in the module, try a more comprehensive search across all modules
    Write-ColorOutput "Performing a more comprehensive search for function app directory..." "Yellow"
    
    # Different search patterns based on the function app name
    $searchPatterns = @("*FuncApps*$appShortName*", "*FuncApps*$appDirName*")
    
    # Special case patterns for specific apps
    if ($appShortName -eq "document") {
        $searchPatterns += "*FuncApps*DocumentManagement*"
    }
    
    # Try each search pattern
    foreach ($pattern in $searchPatterns) {
        $foundDirs = Get-ChildItem -Path $OutputDir -Directory -Recurse -Filter $pattern | 
                    Where-Object { $_.FullName -notlike "*Test*" } | 
                    Select-Object -First 1 -ExpandProperty FullName
        
        if ($foundDirs) {
            return $foundDirs
        }
    }
    
    # If we still can't find it, return the most likely path as a best guess
    if ($ProjectPattern -like "Enterprise*") {
        return (Join-Path $OutputDir $ModuleName "Enterprise.FuncApps.$appDirName")
    }
    elseif ($ProjectPattern -eq "DOMAIN2") {
        return (Join-Path $OutputDir $ModuleName "DOMAIN2.FuncApps.$appDirName")
    }
    else {
        return (Join-Path $OutputDir $ModuleName "DOMAIN1.FuncApps.$appDirName")
    }
}

# Function to generate settings file with KeyVault resolution
function New-SettingsFile {
    param (
        [string]$AppName,
        [string]$TargetDir,
        [bool]$HasKeyVaultAccess,
        [string]$ResourceGroup,
        [string]$KeyVaultName,
        [string]$LocalSettingsFilename
    )
    
    Write-ColorOutput "Retrieving app settings from Azure for $AppName..." "Cyan"
    
    $outputFile = Join-Path $TargetDir $LocalSettingsFilename
    
    try {
        # Get app settings
        $settingsList = az functionapp config appsettings list `
            --resource-group $ResourceGroup `
            --name $AppName `
            --query "[].{name:name, value:value}" 2>$null | ConvertFrom-Json
        
        if ($null -eq $settingsList) {
            Write-ColorOutput "Error retrieving settings for $AppName. Check your permissions." "Red"
            return $false
        }
        
        # Count settings retrieved
        $settingsCount = $settingsList.Count
        Write-ColorOutput "Retrieved $settingsCount app settings for $AppName" "Green"
        
        # Create the settings object structure
        $settingsObject = @{
            IsEncrypted = $false
            Values = [ordered]@{}
            Host = @{
                CORS = "*"
            }
        }
        
        # Process each setting and add it to the object
        $keyvaultRefsCount = 0
        $resolvedRefsCount = 0
        $tempSettings = @{}
        
        foreach ($setting in $settingsList) {
            $name = $setting.name
            $value = $setting.value
            
            # Handle KeyVault references
            if ($value -like "@Microsoft.KeyVault*") {
                $keyvaultRefsCount++
                
                # Extract the secret name from KeyVault reference
                # The pattern might look like: @Microsoft.KeyVault(SecretUri=https://kv-name.vault.azure.net/secrets/secret-name)
                $secretName = $null
                if ($value -match "secrets/([^/)]+)") {
                    $secretName = $matches[1]
                    
                    if ($secretName) {
                        if ($HasKeyVaultAccess) {
                            # Try to get the actual secret value from KeyVault
                            $resolvedValue = Get-KeyVaultSecret -SecretName $secretName -KeyVaultName $KeyVaultName
                            
                            if (-not $resolvedValue.StartsWith("KEY_VAULT_VALUE_FOR_")) {
                                $value = $resolvedValue
                                $resolvedRefsCount++
                                Write-ColorOutput "Successfully resolved KeyVault reference for: $secretName" "Green"
                            }
                            else {
                                $value = $resolvedValue
                                Write-ColorOutput "Could not resolve KeyVault reference for: $secretName" "Yellow"
                            }
                        }
                        else {
                            # Clean the secret name (remove any trailing parenthesis)
                            $cleanSecretName = $secretName -replace "\)$", ""
                            $value = "KEY_VAULT_VALUE_FOR_$cleanSecretName"
                            Write-ColorOutput "Found KeyVault reference for: $secretName (not resolved)" "Yellow"
                        }
                    }
                }
            }
            
            # Add the setting to a temporary hashtable, but don't add settings that will be overridden
            if (-not $HardcodedSettings.ContainsKey($name) -and $name -ne "DbOptions:ConnectionString") {
                $tempSettings[$name] = $value
            }
        }
        
        # Sort the settings alphabetically by key and add to the ordered dictionary
        $tempSettings.GetEnumerator() | Sort-Object -Property Name | ForEach-Object {
            $settingsObject.Values[$_.Name] = $_.Value
        }
        
        # Add hardcoded settings - these will override any retrieved values
        # Add them in alphabetical order as well
        $HardcodedSettings.GetEnumerator() | Sort-Object -Property Name | ForEach-Object {
            $settingsObject.Values[$_.Name] = $_.Value
            Write-ColorOutput "Applied hardcoded value for: $($_.Name)" "Cyan"
        }
        
        # Set the database connection string (add last or in its sorted position)
        $settingsObject.Values["DbOptions:ConnectionString"] = $DbConnectionString
        Write-ColorOutput "Applied database connection string with custom password" "Cyan"
        
        # Resort the entire Values collection to ensure everything is alphabetical
        # Create a new ordered dictionary
        $sortedValues = [ordered]@{}
        
        # Sort and add all values
        $settingsObject.Values.GetEnumerator() | Sort-Object -Property Name | ForEach-Object {
            $sortedValues[$_.Name] = $_.Value
        }
        
        # Replace the Values with sorted values
        $settingsObject.Values = $sortedValues
        
        # Convert to JSON with proper formatting and write to file
        $settingsJson = $settingsObject | ConvertTo-Json -Depth 10
        
        # Ensure the directory exists
        $dirPath = Split-Path -Path $outputFile -Parent
        if (-not (Test-Path -Path $dirPath -PathType Container)) {
            New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
        }
        
        # Write the JSON to the file
        $settingsJson | Out-File -FilePath $outputFile -Encoding utf8
        
        # Validate the JSON file
        if (-not (Test-Path $outputFile) -or (Get-Content $outputFile -Raw) -notlike '*"Values"*') {
            Write-ColorOutput "Error: Generated file appears to be invalid" "Red"
            return $false
        }
        
        # Summary of KeyVault references
        if ($keyvaultRefsCount -gt 0) {
            Write-ColorOutput "KeyVault References Summary for ${AppName}:" "Cyan"
            Write-ColorOutput "- Total KeyVault references found: $keyvaultRefsCount" "Cyan"
            
            if ($HasKeyVaultAccess) {
                Write-ColorOutput "- Successfully resolved: $resolvedRefsCount" "Cyan"
                Write-ColorOutput "- Failed to resolve: $($keyvaultRefsCount-$resolvedRefsCount)" "Cyan"
            }
            else {
                Write-ColorOutput "- None resolved (no KeyVault access)" "Yellow"
            }
        }
        
        Write-ColorOutput "Successfully updated $LocalSettingsFilename at $outputFile with alphabetically sorted settings" "Green"
        return $true
    }
    catch {
        Write-ColorOutput "Error generating settings file: $_" "Red"
        return $false
    }
}

# Function to process a single function app
function Process-FunctionApp {
    param (
        [string]$AppInfo,
        [bool]$HasKeyVaultAccess,
        [string]$ResourceGroup,
        [string]$KeyVaultName,
        [string]$OutputDir,
        [string]$LocalSettingsFilename
    )
    
    # Split the app info into function app name, module name, and project pattern
    $appParts = $AppInfo -split ":"
    $appName = $appParts[0]
    $moduleName = $appParts[1]
    $projectPattern = $appParts[2]
    
    Write-ColorOutput "`nProcessing Function App: $appName (Module: $moduleName, Pattern: $projectPattern)" "Blue" 
    
    # Get the target directory for the function app
    $targetDir = Get-FunctionAppDirectory -AppName $appName -ModuleName $moduleName -ProjectPattern $projectPattern
    
    if (Test-Path $targetDir -PathType Container) {
        Write-ColorOutput "Found function app directory: $targetDir" "Green"
    }
    else {
        Write-ColorOutput "Could not find exact function app directory. Using best guess: $targetDir" "Yellow"
        # Create the directory if it doesn't exist
        try {
            New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
            Write-ColorOutput "Created directory: $targetDir" "Green"
        }
        catch {
            Write-ColorOutput "Failed to create directory $targetDir. Skipping this function app." "Red"
            return $false
        }
    }
    
    # Generate the settings file with KeyVault resolution if possible
    $result = New-SettingsFile -AppName $appName -TargetDir $targetDir -HasKeyVaultAccess $HasKeyVaultAccess `
                          -ResourceGroup $ResourceGroup -KeyVaultName $KeyVaultName -LocalSettingsFilename $LocalSettingsFilename
    
    if (-not $result) {
        Write-ColorOutput "Failed to update settings file for $appName. Skipping and continuing with other function apps." "Red"
        return $false
    }
    
    return $true
}

# Main script execution
function Main {
    Write-Host "==========================================================" -ForegroundColor Blue
    Write-Host "   Azure Function Apps Settings Synchronizer (KeyVault)   " -ForegroundColor Blue
    Write-Host "==========================================================" -ForegroundColor Blue
    Write-Host ""
    
    # Display parameter information
    Write-Host "Using Database Password: " -NoNewline
    if ($DbPassword -eq "VerySecurePaddword123") {
        Write-Host "DEFAULT (you can specify a custom password with -DbPassword parameter)" -ForegroundColor Yellow
    } else {
        Write-Host "CUSTOM (provided via parameter)" -ForegroundColor Green
    }
    
    # Check Azure CLI installation
    if (-not (Test-AzureCliInstallation)) {
        return
    }
    
    # Check Azure login
    if (-not (Test-AzureLogin)) {
        return
    }
    
    # Check KeyVault access - this affects all function apps
    $hasKeyVaultAccess = Test-KeyVaultAccess -KeyVaultName $KeyVaultName
    # Explicitly convert to boolean to avoid type conversion issues
    $hasKeyVaultAccess = [bool]$hasKeyVaultAccess
    
    Write-Host "`nWill process $($FunctionApps.Count) function apps`n" -ForegroundColor Cyan
    
    # Initialize counters
    $processedCount = 0
    $successCount = 0
    $failureCount = 0
    
    # Process each function app
    foreach ($appInfo in $FunctionApps) {
        $processedCount++
        
        Write-Host "[$processedCount/$($FunctionApps.Count)] Processing function app: $appInfo" -ForegroundColor Cyan
        
        $success = Process-FunctionApp -AppInfo $appInfo -HasKeyVaultAccess $hasKeyVaultAccess `
                              -ResourceGroup $ResourceGroup -KeyVaultName $KeyVaultName `
                              -OutputDir $OutputDir -LocalSettingsFilename $LocalSettingsFilename
        
        if ($success) {
            $successCount++
        }
        else {
            $failureCount++
        }
        
        # Add a separator between function apps
        Write-Host "`n--------------------------------------------------------`n" -ForegroundColor Blue
    }
    
    # Final summary
    Write-Host "`n==========================================================" -ForegroundColor Blue
    Write-Host "                      Final Summary                      " -ForegroundColor Blue
    Write-Host "==========================================================" -ForegroundColor Blue
    Write-Host ""
    
    Write-Host "Total function apps processed: $($FunctionApps.Count)" -ForegroundColor Cyan
    Write-Host "Successfully updated: $successCount" -ForegroundColor Green
    
    if ($failureCount -gt 0) {
        Write-Host "Failed to update: $failureCount" -ForegroundColor Red
    }
    
    if ($hasKeyVaultAccess) {
        Write-Host "KeyVault access: Yes - Secrets were retrieved from KeyVault" -ForegroundColor Green
    }
    else {
        Write-Host "KeyVault access: No - Secret values are placeholder markers" -ForegroundColor Yellow
    }
    
    Write-Host "`nHardcoded values applied to all function apps:" -ForegroundColor Cyan
    foreach ($key in $HardcodedSettings.Keys) {
        Write-Host "- $key" -ForegroundColor Cyan
    }
    Write-Host "- DbOptions:ConnectionString (with custom password)" -ForegroundColor Cyan
    
    Write-Host "`nScript completed successfully." -ForegroundColor Green
}

# Run the main function
Main