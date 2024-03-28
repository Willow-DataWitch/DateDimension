CREATE SCHEMA [datedim] AUTHORIZATION [dbo];
GO

CREATE FUNCTION [datedim].[DateToDateSK_ufn] (
    @Input VARCHAR(50)
)
RETURNS INT
AS BEGIN
DECLARE @DateSK INT;
DECLARE @Date DATE;

SET @Date = TRY_CONVERT(DATE,@Input);

IF @Date IS NULL
BEGIN
    SET @DateSK = -1
END
ELSE
BEGIN
    IF @DATE = CAST('9999-12-31' AS DATE)
    BEGIN
        SET @DateSK = 99999999;
    END
    ELSE
    BEGIN
        SET @DateSK = YEAR(@Date) * 10000 + MONTH(@Date) * 100 + DAY(@Date);
    END
END

RETURN @DateSK;
END

GO

CREATE TABLE [datedim].[datedim] (
     [SK_Date]   INT NOT NULL PRIMARY KEY
    ,[Date_DT] DATE NULL
    ,CONSTRAINT [datedim_datedim_Date_DT_unq] UNIQUE ([Date_DT])
    ,CONSTRAINT [datedim_datedim_Date_Txt_unq] UNIQUE ([Date_Txt])
    ,[AsOfDate_DT] DATE NOT NULL CONSTRAINT [datedim_datedim_AsOfDate_DT_df] DEFAULT '1999-01-01'
    ,[FiscalDateOffsetInMonths] INT NOT NULL CONSTRAINT [datedim_datedim_FiscalDateOffsetInMonths_df] DEFAULT 0
    
    /*From here down, it's all computed columns, persisted when possible. Make sure they render well as text, because remember, you are using them as reporting headers.*/
    ,[DaysBeforeAsOfDate] AS DATEDIFF(day, [Date_DT], [AsOfDate_DT]) PERSISTED
    ,[Date_Txt] AS CONVERT(VARCHAR(50),[Date_DT],120) PERSISTED
    ,[DayNumberOfWeek] AS DATEPART(dw, [Date_DT])
    ,[EnglishDayNameOfWeek] AS DATENAME(WEEKDAY, [Date_DT])
    ,[DayNumberOfMonth] AS DAY([Date_DT]) PERSISTED
    ,[DayNumberOfYear] AS DATEPART(dy, [Date_DT]) PERSISTED
    ,[WeekNumberOfYear] AS DATEPART(wk, [Date_DT])
    ,[EnglishMonthName] AS DATENAME(Month, [Date_DT])
    ,[MonthNumberOfYear] AS MONTH([Date_DT]) PERSISTED
    ,[CalendarQuarter] AS DATEPART(q, [Date_DT]) PERSISTED
    ,[CalendarYear] AS YEAR([Date_DT]) PERSISTED
    ,[CalendarSemester] AS CASE WHEN MONTH([Date_DT]) < 7 THEN 1 ELSE 2 END PERSISTED
    ,[FiscalQuarter] AS DATEPART(q, DATEADD(MONTH,[FiscalDateOffsetInMonths],[Date_DT])) PERSISTED
    ,[FiscalYear] AS YEAR(DATEADD(MONTH,[FiscalDateOffsetInMonths],[Date_DT])) PERSISTED
    ,[FiscalSemester] AS CASE WHEN MONTH(DATEADD(MONTH,[FiscalDateOffsetInMonths],[Date_DT])) < 7 THEN 1 ELSE 2 END PERSISTED
    ,[CalendarYearAndMonthNumber] AS CAST( CAST(YEAR([Date_DT]) AS VARCHAR(10) ) + RIGHT('00' + CAST(MONTH([Date_DT]) AS VARCHAR(10) ) , 2) AS INT)

    /*These are relative. They get recalculated when you update the [AsOfDate_DT] column.*/
    ,[PastAndFuture] AS CASE WHEN [Date_DT] > [AsOfDate_DT] THEN 'The Past' WHEN [Date_DT] < [AsOfDate_DT] THEN 'The Future' WHEN [Date_DT] = [AsOfDate_DT] THEN 'As-Of Date' ELSE 'Unknown' END PERSISTED
    ,[ThisMonth] AS CASE WHEN YEAR([Date_DT]) = YEAR([AsOfDate_DT]) AND MONTH([Date_DT]) = MONTH([AsOfDate_DT]) THEN 'This Month' ELSE 'Not This Month' END PERSISTED
    ,[Prior30Days] AS CASE WHEN [Date_DT] < [AsOfDate_DT] AND [DATE_DT] >= DATEADD(DAY, -30,[AsOfDate_DT]) THEN 'Prior 30 Days' ELSE 'Not Prior 30 Days' END PERSISTED
    ,[PriorMonth] AS CASE WHEN EOMONTH([Date_DT]) = EOMONTH(DATEADD(MONTH,-1,[AsOfDate_DT])) THEN 'Prior Month' ELSE 'Not Prior Month' END PERSISTED
    ,[CummulativeThroughPriorMonth] AS CASE WHEN [Date_DT] <= EOMONTH(DATEADD(MONTH,-1,[AsOfDate_DT])) THEN 'Cummulative through Prior Month' ELSE 'Not Cummulative through Prior Month' END PERSISTED
    ,[ThisFiscalYearThroughPriorMonth] AS CASE WHEN YEAR(DATEADD(MONTH,[FiscalDateOffsetInMonths],[Date_DT])) = YEAR(DATEADD(MONTH,[FiscalDateOffsetInMonths],[AsOfDate_DT])) AND [Date_DT] <= EOMONTH(DATEADD(MONTH,-1,[AsOfDate_DT])) THEN 'This Fiscal Year Through Prior Month' ELSE 'Not This Fiscal Year Through Prior Month' END PERSISTED
    ,[ThisCalendarYearThroughPriorMonth] AS CASE WHEN YEAR([Date_DT]) = YEAR([AsOfDate_DT]) AND [Date_DT] <= EOMONTH(DATEADD(MONTH,-1,[AsOfDate_DT])) THEN 'This Calendar Year Through Prior Month' ELSE 'Not This Calendar Year Through Prior Month' END PERSISTED
    ,[PriorMonthYearOverYear] AS CASE WHEN EOMONTH([Date_DT]) = EOMONTH(DATEADD(MONTH,-1,[AsOfDate_DT])) THEN 'Prior Month This Year' WHEN EOMONTH([Date_DT]) = EOMONTH(DATEADD(MONTH,-1,DATEADD(YEAR,-1,[AsOfDate_DT]))) THEN 'Prior Month Last Year'  ELSE 'Not Prior Month Year Over Year' END PERSISTED
    ,[RecentFiscalYears] AS CASE WHEN YEAR(DATEADD(MONTH,[FiscalDateOffsetInMonths],[Date_DT])) = YEAR(DATEADD(MONTH,[FiscalDateOffsetInMonths],[AsOfDate_DT])) THEN 'This Fiscal Year' WHEN YEAR(DATEADD(MONTH,[FiscalDateOffsetInMonths],[Date_DT])) = YEAR(DATEADD(MONTH,[FiscalDateOffsetInMonths],DATEADD(YEAR,-1,[AsOfDate_DT]))) THEN 'Prior Fiscal Year' ELSE 'Not Recent Fiscal Year' END PERSISTED
)
GO
CREATE PROCEDURE [datedim].[datedim_maintenance_unknownMember_usp] AS
IF (SELECT COUNT(1) FROM [datedim].[datedim] WHERE [SK_Date] = -1) = 0
BEGIN
INSERT INTO [datedim].[datedim]
(
    [SK_Date]
    ,[Date_DT]
)
SELECT
     -1 AS [SK_Date]
    ,NULL AS [Date_DT]
END
GO
CREATE TABLE [datedim].[config]
(
         [Id] INT NOT NULL PRIMARY KEY DEFAULT (1)
        ,CONSTRAINT [ck_datedime_config_Id] CHECK ([Id] = 1)
        ,[AsOfDate] DATE NOT NULL DEFAULT ('2024-01-01')
        ,[StartDate] DATE NOT NULL DEFAULT ('1999-01-01')
        ,[EndDate] DATE NOT NULL DEFAULT ('2040-12-31')
        ,[FiscalDateOffsetInMonths] INT NOT NULL DEFAULT (0)
)
GO
CREATE PROCEDURE [datedim].[config_usp]
         @AsOfDate DATE = NULL
        ,@StartDate DATE = NULL
        ,@EndDate DATE = NULL
        ,@FiscalDateOffsetInMonths INT = NULL
        ,@ForceRebuild BIT = 0
AS

IF (SELECT [Id] FROM [datedim].[config]) IS NULL
BEGIN
        INSERT INTO [datedim].[config] (
                [Id]
        )
        VALUES (
                default
        );
END

UPDATE [a]
SET
[Id] = default
,[AsOfDate] = COALESCE(@AsOfDate, [a].[AsOfDate])
,[StartDate] = COALESCE(@StartDate, [a].[StartDate])
,[EndDate] = COALESCE(@EndDate, [a].[EndDate])
,[FiscalDateOffsetInMonths] = COALESCE(@FiscalDateOffsetInMonths, [a].[FiscalDateOffsetInMonths])
FROM [datedim].[config] AS [a];

IF (SELECT MAX([Date_DT]) FROM [datedim].[datedim] ) <> @EndDate
    OR (SELECT MAX([Date_DT]) FROM [datedim].[datedim] ) IS NULL
    OR (SELECT MIN([Date_DT]) FROM [datedim].[datedim] ) <> @StartDate
    OR (SELECT MIN([Date_DT]) FROM [datedim].[datedim] ) IS NULL
    OR @ForceRebuild = 1
BEGIN
DELETE [datedim].[datedim];
EXEC [datedim].[datedim_maintenance_usp];
END
GO

CREATE PROCEDURE [datedim].[AsOfDateIs_usp]
         @AsOfDate DATE = NULL
AS
EXEC [datedim].[config_usp] @AsOfDate = @AsOfDate;
GO

CREATE PROCEDURE [datedim].[datedim_maintenance_usp]
AS
IF (SELECT COUNT(1) FROM [datedim].[datedim] ) = 0
BEGIN /*Begin If table is null, repopulate*/
EXEC [datedim].[datedim_maintenance_unknownMember_usp];
DECLARE @TheDate DATE = (SELECT MAX([StartDate]) FROM [datedim].[config]);
DECLARE @EndDate DATE = (SELECT MAX([EndDate]) FROM [datedim].[config]);

WHILE (@TheDate <= @EndDate)
BEGIN /*Begin While looping dates*/
    INSERT INTO [datedim].[datedim]
    (SK_Date
    ,Date_DT)
    SELECT 
    [datedim].[DateToDateSK_ufn](@TheDate)
    , @TheDate;

    /*Increment*/
    SET @TheDate = DATEADD(DAY,1,@TheDate);
END /*End While looping dates*/
END /*End If table is null, repopulate*/

UPDATE [d]
SET [d].[AsOfDate_DT] = [config].[AsOfDate]
,[d].[FiscalDateOffsetInMonths] = [config].[FiscalDateOffsetInMonths]
FROM [datedim].[datedim] AS [d]
CROSS JOIN [datedim].[config]

GO
