Param(
    [int32]$numberOfVMs,
    [string]$resourceGroupName
    )

$ErrorActionPreference = "stop"

$passwords = New-Object 'System.Collections.Generic.List[string]'
for ($i =0; $i -lt $numberOfVMs; $i++){
    # https://github.com/kpatnayakuni/azps-extracts/tree/master/extract-017
    $password =  -join ((33..126) | Get-Random -Count 12 | ForEach-Object { [char]$_ })
    $passwords.add($password)
}

New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name New-AzWin10LabEnv -TemplateFile .\main.bicep -numberOfVMs $numberOfVMs -passwords $passwords