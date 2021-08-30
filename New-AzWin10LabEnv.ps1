Param(
    [int32]$numberOfVMs,
    [string]$resourceGroupName
    )

$ErrorActionPreference = "stop"

$passwords = New-Object 'System.Collections.Generic.List[string]'
for ($i =0; $i -lt $numberOfVMs; $i++){
    $password = Get-Random -Maximum 100000000
    $passwords.add($password)
}

New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name New-AzWin10LabEnv -TemplateFile .\main.bicep -numberOfVMs $numberOfVMs -passwords $passwords
