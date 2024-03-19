# Date Dimensions
They're really useful for reporting. IYKYK.

## But why this one?
Because I made it just the way I like it.

## Any other reason?
- "AsOfDate" is configurable.
- The fiscal date offset is configurable.
- The attributes are developed as T-SQL persisted computed columns on a table, which makes this date dimension pretty straightforward to extend to include the date dimensional attributes your end users cannot live without.

## Supported Database Engines?
I wrote it for SQL Server 2019. It probably works for many versions of SQL Server, but I doubt the date functions are the same on other dialects of SQL. That said, you could probably adapt it pretty quickly. You could even send me pull request with your fancy postgres version.

## What's it do?
- Makes a schema: [datedim]
- Makes a table: [datedim].[datedim]
- Makes a config table: [datedim].[config]
- Makes a config stored procedure: [datedim].[config_usp]
- Makes a table maintenance stored procedure: [datedim].[datedim_maintenance_usp]
- Makes a shortcut stored procedure: [datedim].[AsOfDateIs_usp]
- Makes a scalar function to convert dates to SK Integers: [datedim].[DateToDateSK_ufn]

## How do I join to it?
Convert your dates with [datedim].[DateToDateSK_ufn] and join on [SK_Date]. It has a yyyyMMdd formatted integer for the SK. This is one of only a tiny handful of cases when I endorse smart-keys for your surrogate keys.

## How do I use this script?
Two options:

### Just point a script somewhere
1. Have dbatools installed.
   - dbatools.io - go install that. It's wonderful. ```choco install dbatools -y; ```
1. Clone this repo.
1. Run in PowerShell
    ```powershell
    .\deploy-dateDim.ps1 -SQLInstance 'YourServerInstanceHere' -Database 'Your database name here';
    ```

### Just give me the SQL
You want .\script.sql - run that on your SQL server in the database where you want these objects deployed.

### Maintenance
1. When you want "AsOfDate" to change (probably every time you load your data warehouse), run
   - in PowerShell:
        ```powershell
        .\config-dateDim.ps1 -SQLInstance 'YourServerInstanceHere' -Database 'Your database name here' -AsOfDate $(Get-Date);
        ```
   - or in SQL:
        ```sql
        EXEC [datedim].[AsOfDateIs_usp] '1999-01-01'; /*<-- Update that date.*/
        ```
1. When you first set this up (or as needed), set the fiscaldate offset, in months, like this (6 would be a fiscal year that starts on July 1st. January 1, 2000 + 6 months = July 1, 2000. January 1, 2000 + -6 months = July 1, 1999):
   - in PowerShell:
        ```powershell
        .\config-dateDim.ps1 -SQLInstance 'YourServerInstanceHere' -Database 'Your database name here' -FiscalDateOffsetInMonths 6;
        ```
   - or in SQL:
        ```sql
        EXEC [datedim].[config_usp] @FiscalDateOffsetInMonths = 6;
        ```
1. As needed (rarely, one hopes), set the start and end of the datedim like this (it defaults to 2000-2040):
   - in PowerShell:
        ```powershell
        .\config-dateDim.ps1 -SQLInstance 'YourServerInstanceHere' -Database 'Your database name here' -Start '1999-01-01' -End '2999-01-01' ;
        ```
   - or in SQL:
        ```sql
        EXEC [datedim].[config_usp] @Start = '1999-01-01', @End = '2999-01-01'; /*<-- Update that date.*/
        ```

## I want to customize the date attributes
```sql
ALTER TABLE blah blah blah
```
BUT! If you want the config_usp to keep working, don't mess with the non-computed columns. Also, if you run .\deploy-dateDim.ps1 -Force, all your changes are getting dropped. Along with all your other configs, so, use with caution.

## What's a computed column?
https://www.google.com/search?q=sql+server+computed+column

## I want a role-play dimension of this for each of my many dates
Someday I might post my script for that.

## What's SQL?
May I interest you in my services as a consultant?
