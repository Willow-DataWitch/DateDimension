[CmdletBinding()]
param (
    [Parameter(Mandatory= $true)]$SQLInstance
    ,[Parameter(Mandatory= $true)]$Database
    ,[Parameter(Mandatory= $false)][DateTime]$AsOfDate
    ,[Parameter(Mandatory= $false)][DateTime]$StartDate
    ,[Parameter(Mandatory= $false)][DateTime]$EndDate
    ,[Parameter(Mandatory= $false)][Int]$FiscalDateOffsetInMonths
    ,[Parameter(Mandatory= $false)][Boolean]$ForceRebuild
)
Import-Module dbatools;
$Query = @"
EXEC [datedim].[config_usp] 
    @AsOfDate = $( if ($AsOfDate -like $null) {"NULL"} else {"'" + $AsOfDate + "'"} )
    ,@StartDate = $( if ($StartDate -like $null) {"NULL"} else {"'" + $StartDate + "'"} )
    ,@EndDate = $( if ($EndDate -like $null) {"NULL"} else {"'" + $EndDate + "'"} )
    ,@FiscalDateOffsetInMonths = $( if ($FiscalDateOffsetInMonths -like $null) {"NULL"} else {"'" + $FiscalDateOffsetInMonths + "'"} )
    ,@ForceRebuild = $( if ($ForceRebuild -like $null) {"0"} else {"'" + [Int]$ForceRebuild + "'"} )
;
"@
Invoke-DbaQuery -SQLInstance $SQLInstance -Database $Database -Query $Query;
