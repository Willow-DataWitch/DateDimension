[CmdletBinding()]
param (
    [Parameter(Mandatory= $true)]$SQLInstance
    ,[Parameter(Mandatory= $true)]$Database
)
Import-Module dbatools;
Invoke-DbaQuery -SQLInstance $SQLInstance -Database $Database -Query $PSScriptRoot\script.sql;
