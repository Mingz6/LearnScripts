# Install-Module -Name Az -Force -AllowClobber
# .\copySecrets.ps1 -sourceKvName "sourceKeyvault" -destKvName "destinationKeyvault"

Param(
    [Parameter(Mandatory)]
    [string]$sourceKvName
    [Parameter(Mandatory)]
    [string]$destKvName
)

# Connect to your Azure account
Connect-AzAccount

# Get all the secrets from the source KeyVault
$secretNames = (Get-AzKeyVaultSecret -VaultName $sourceKvName).Name

# Loop through each secret and copy it to the destination KeyVault
foreach ($name in $secretNames) {
    $secret = Get-AzKeyVaultSecret -VaultName $sourceKvName -Name $name
    $secretValue = (Get-AzKeyVaultSecret -VaultName $sourceKvName -Name $name).SecretValue
    Set-AzKeyVaultSecret -VaultName $destKvName -Name $name -SecretValue $secretValue
}
