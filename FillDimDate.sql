--Exec [DW].[FillDimDate] @FromDate = NULL,@UntilDate = '2200-01-01'
ALTER PROCEDURE [DW].[FillDimDate]
@FromDate date ,
@UntilDate date
AS
set nocount on
BEGIN
/*

CREATE TABLE [DW].[DimDate](
	[ID] [int] NOT NULL,
	[Endt] [date] NULL,
	[EnYear] [char](4) NULL,
	[EnMonth] [char](2) NULL,
	[EnDay] [char](2) NULL,
	[Frdt] [char](10) NULL,
	[FrYear] [char](4) NULL,
	[FrMonth] [char](2) NULL,
	[FrDay] [char](2) NULL,
	[Hjdt] [char](10) NULL,
	[HjYear] [char](4) NULL,
	[HjMonth] [char](2) NULL,
	[HjDay] [char](2) NULL,
	[EnMonthName] [nvarchar](50) NULL,
	[EnDayOfWeek] [nvarchar](50) NULL,
	[FrMonthName] [nvarchar](50) NULL,
	[FrDayOfWeek] [nvarchar](50) NULL,
	[EnNoDayOfWeek] [smallint] NULL,
	[FrNoDayOfWeek] [smallint] NULL,
	[WeekOfYr] [int] NULL,
	[WeekOfMnth] [int] NULL,
	[EnWeekOfYr] [int] NULL,
	[SrlWeekOfYr] [int] NULL,
	[SeqID] [int] NULL,
	[FrSrlWeekOfYr] [int] NULL,
	[FrFrstWkDayID] [int] NULL,
	[Qrtr] [tinyint] NULL,
	[QrtrName] [nvarchar](50) NULL,
	[IsHoliday] [bit] NULL,
	[HolidayDesc] [nvarchar](100) NULL,
	[EnDtFormat101] [varchar](50) NULL,
	[IsEndOfMonth] [bit] NULL,
	[MaxFrDayInMonth] [int] NULL,
	[FrIsLeap] [bit] NULL,
	[EnIsLeap] [bit] NULL,
 CONSTRAINT [PK_DimDate] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

*/






	declare @date date 
	if @FromDate is null
	begin
		set @date = dateadd(YEAR,-5,getdate())--isnull(dateadd(Day,1,((select max(Endt) from dw.DimDate))),dateadd(YEAR,-5,getdate()));
	end 
	else 
	begin
		set @date = @FromDate
	end

	set @FromDate = @date



	declare @frdate nvarchar(10),@HjDate nvarchar(10)
	declare @ID int
	declare @table table (ID int, Endt date , EnYear char(4),EnMonth char(2),EnDay char(2),Frdt char(10),FrYear char(4),FrMonth char(2),FrDay char(2)
	,Hjdt nvarchar(10) , HjYear char(4),HjMonth char(2),HjDay char(2) ,EnMonthName nvarchar(50),EnDayOfWeek nvarchar(50),FrMonthName nvarchar(50),FrDayOfWeek nvarchar(50),EnNoDayOfWeek int,FrNoDayOfWeek int)

	declare @DateDiff int = (select DATEDIFF(day,@FromDate,@UntilDate))
	
	;with stp1 as 
	(
		select  ROW_NUMBER() over(Order by a.object_id) as rn from sys.objects a cross join sys.objects b
	)
	select *
	,CAST(DATEADD(DAY,rn-1,@FromDate) as DATE) as EnDt INTO #DimDate
	from stp1 where rn <=@DateDiff

	
	insert into @table
	(ID,Endt,EnYear,EnMonth,EnDay,Frdt,FrYear,FrMonth,FrDay,Hjdt,HjYear,HjMonth,HjDay,EnMonthName,EnDayOfWeek,FrMonthName,FrDayOfWeek,EnNoDayOfWeek,FrNoDayOfWeek)
	select 
		Cast(Format(EnDt,'yyyyMMdd') as int) as ID
		,FORMAT(EnDt,'yyyy/MM/dd') as Endt
		,DATEPART(year,EnDt) as EnYear
		,FORMAT(EnDt,'MM') as EnMonth
		,FORMAT(EnDt,'dd') as EnDay
		,FORMAT(EnDt,'yyyy/MM/dd','fa-IR') as FrDt
		,FORMAT(EnDt,'yyyy','fa-IR') as FrYear
		,FORMAT(EnDt,'MM','fa-IR') as FrMonth
		,FORMAT(EnDt,'dd','fa-IR') as FrDay
		,FORMAT(EnDt,'yyyy/MM/dd','ar') as HjDt
		,FORMAT(EnDt,'yyyy','ar') as HjYear
		,FORMAT(EnDt,'MM','ar') as HjMonth
		,FORMAT(EnDt,'dd','ar') as HjDay
		,FORMAT(EnDt,'MMMM') as EnMonthName
		,DATENAME(WEEKDAY,EnDt) EnDayOfWeek
		,FORMAT(EnDt,'MMMM','fa-IR') as FrMonthName
		,FORMAT(EnDt,'dddd','fa-IR') FrDayOfWeek
		,DATEPART(WEEKDAY,EnDt) as EnNoDayOfWeek
		,case DatePart(WEEKDAY,@date)
											when 1 then 2
											when 2 then 3
											when 3 then 4
											when 4 then 5
											when 5 then 6
											when 6 then 7
											when 7 then 1
		end FrNoDayOfWeek	
	from #DimDate

		
	insert into dw.DimDate(ID,Endt,EnYear,EnMonth,EnDay,Frdt,FrYear,FrMonth,FrDay,Hjdt,HjYear,HjMonth,HjDay,EnMonthName,EnDayOfWeek
	,FrMonthName,FrDayOfWeek,EnNoDayOfWeek,FrNoDayOfWeek,SeqID)
	select ID,Endt,EnYear,EnMonth,EnDay,Frdt,FrYear,FrMonth,FrDay,Hjdt,HjYear,HjMonth,HjDay,EnMonthName,EnDayOfWeek
	,FrMonthName,FrDayOfWeek,EnNoDayOfWeek,FrNoDayOfWeek,convert(int,cast(Endt as datetime)) as SeqID  
	from @table



/* فصلهای سال 

ALTER TABLE dw.DimDate 
ADD Qrtr TINYINT

ALTER TABLE dw.DimDate 
ADD QrtrName NVARCHAR(50)
*/

Update dd set Qrtr = 1 , QrtrName = N'بهار'  FROM DW.DimDate dd WHERE FrMonth BETWEEN 1 AND 3 AND QrtrName IS NULL 
Update dd set Qrtr = 2 , QrtrName = N'تابستان'  FROM DW.DimDate dd WHERE FrMonth BETWEEN 4 AND 6 AND QrtrName IS NULL 
Update dd set Qrtr = 3 , QrtrName = N'پاییز'  FROM DW.DimDate dd WHERE FrMonth BETWEEN 7 AND 9 AND QrtrName IS NULL 
Update dd set Qrtr = 4 , QrtrName = N'زمستان'  FROM DW.DimDate dd WHERE FrMonth BETWEEN 10 AND 13 AND QrtrName IS NULL 





--Miladi
Declare @Yr int = 2014

while (@Yr <= 2025 )
begin 
--N'Sunday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where EnYear = @Yr and EnDayOfWeek = N'Sunday' 
and ID >= (select Min(ID) from Dw.DimDate where EnYear = @Yr and EnDayOfWeek = N'Sunday'
))
Update dd set EnWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND EnWeekOfYr IS NULL

--N'Monday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where EnYear = @Yr and EnDayOfWeek = N'Monday' 
and ID >= (select Min(ID) from Dw.DimDate where EnYear = @Yr and EnDayOfWeek = N'Sunday'
))
Update dd set EnWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND EnWeekOfYr IS NULL 

--N'Tuesday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where EnYear = @Yr and EnDayOfWeek = N'Tuesday' 
and ID >= (select Min(ID) from Dw.DimDate where EnYear = @Yr and EnDayOfWeek = N'Sunday'
))
Update dd set EnWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND EnWeekOfYr IS NULL 

--N'Thursday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where EnYear = @Yr and EnDayOfWeek = N'Thursday' 
and ID >= (select Min(ID) from Dw.DimDate where EnYear = @Yr and EnDayOfWeek = N'Sunday'
))
Update dd set EnWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND EnWeekOfYr IS NULL 


--N'Wednesday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where EnYear = @Yr and EnDayOfWeek = N'Wednesday' 
and ID >= (select Min(ID) from Dw.DimDate where EnYear = @Yr and EnDayOfWeek = N'Sunday'
))
Update dd set EnWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND EnWeekOfYr IS NULL 


--N'Friday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where EnYear = @Yr and EnDayOfWeek = N'Friday' 
and ID >= (select Min(ID) from Dw.DimDate where EnYear = @Yr and EnDayOfWeek = N'Sunday'
))
Update dd set EnWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND EnWeekOfYr IS NULL 

--N'Saturday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where EnYear = @Yr and EnDayOfWeek = N'Saturday' 
and ID >= (select Min(ID) from Dw.DimDate where EnYear = @Yr and EnDayOfWeek = N'Sunday'
))
Update dd set EnWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND EnWeekOfYr IS NULL 
set @Yr = @Yr + 1
end 
Update DW.DimDate set EnWeekOfYr = 0 where EnWeekOfYr is null 



-- شمسی
--Declare @Yr int = 2014
SET @Yr = 1393

while (@Yr <= 1403 )
begin 
--N'Sunday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where FrYear = @Yr and FrDayOfWeek = N'شنبه' 
and ID >= (select Min(ID) from Dw.DimDate where FrYear = @Yr and FrDayOfWeek = N'شنبه'
))
Update dd set WeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND WeekOfYr IS NULL 

--N'Monday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where FrYear = @Yr and FrDayOfWeek = N'یک شنبه' 
and ID >= (select Min(ID) from Dw.DimDate where FrYear = @Yr and FrDayOfWeek = N'شنبه'
))
Update dd set WeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID  AND WeekOfYr IS NULL 

--N'Tuesday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where FrYear = @Yr and FrDayOfWeek = N'دو شنبه' 
and ID >= (select Min(ID) from Dw.DimDate where FrYear = @Yr and FrDayOfWeek = N'شنبه'
))
Update dd set WeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID  AND WeekOfYr IS NULL 


--N'Wednesday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where FrYear = @Yr and FrDayOfWeek = N'سه شنبه' 
and ID >= (select Min(ID) from Dw.DimDate where FrYear = @Yr and FrDayOfWeek = N'شنبه'
))
Update dd set WeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID  AND WeekOfYr IS NULL 


--N'Thursday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where FrYear = @Yr and FrDayOfWeek = N'چهار شنبه' 
and ID >= (select Min(ID) from Dw.DimDate where FrYear = @Yr and FrDayOfWeek = N'شنبه'
))
Update dd set WeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID  AND WeekOfYr IS NULL 
 
--N'Friday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where FrYear = @Yr and FrDayOfWeek = N'پنج شنبه' 
and ID >= (select Min(ID) from Dw.DimDate where FrYear = @Yr and FrDayOfWeek = N'شنبه'
))
Update dd set WeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID  AND WeekOfYr IS NULL 

--N'Saturday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where FrYear = @Yr and FrDayOfWeek = N'جمعه' 
and ID >= (select Min(ID) from Dw.DimDate where FrYear = @Yr and FrDayOfWeek = N'شنبه'
))
Update dd set WeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID  AND WeekOfYr IS NULL 
set @Yr = @Yr + 1
end 
Update DW.DimDate set WeekOfYr = 0 where WeekOfYr is null 





-- توليد هفته ماه
--ALTER TABLE DimDate_New
--ADD WeekOfMnth int
--Declare @Yr int = 2014
SET @yr = 1356
DECLARE @Mnth INT = 1
DECLARE @WNmbr TINYINT = 1 
DECLARE @tb TABLE (id int)

WHILE (@yr < = 1405)
BEGIN 
SET @WNmbr = 1
SET @Mnth = 1

WHILE (@Mnth <= 12)
BEGIN
SET @WNmbr = 1	
WHILE (@WNmbr <= 5)
BEGIN 	
PRINT @WNmbr
INSERT INTO @tb
SELECT TOP 7 id FROM DW.DimDate AS dd WHERE WeekOfMnth IS NULL AND  fryear = @yr AND dd.FrMonth = @Mnth
ORDER BY id
UPDATE d SET WeekOfMnth = @WNmbr FROM DW.DimDate d inner JOIN @tb t ON t.id = d.id
AND fryear = @yr AND FrMonth = @Mnth AND WeekOfMnth IS NULL 
DELETE @tb 
SET @WNmbr = @WNmbr + 1
END 
SET @Mnth = @Mnth + 1
end
set @yr =1 +@yr 
END

--SELECT * FROM DimDate



--N'Sunday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where EnDayOfWeek = N'Sunday' 
and ID >= (select Min(ID) from Dw.DimDate where EnDayOfWeek = N'Sunday'
))
Update dd set SrlWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND SrlWeekOfYr IS NULL 

--N'Monday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where  EnDayOfWeek = N'Monday' 
and ID >= (select Min(ID) from Dw.DimDate where  EnDayOfWeek = N'Sunday'
))
Update dd set SrlWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND SrlWeekOfYr IS NULL 

--N'Tuesday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where  EnDayOfWeek = N'Tuesday' 
and ID >= (select Min(ID) from Dw.DimDate where  EnDayOfWeek = N'Sunday'
))
Update dd set SrlWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND SrlWeekOfYr IS NULL 

--N'Thursday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where  EnDayOfWeek = N'Thursday' 
and ID >= (select Min(ID) from Dw.DimDate where  EnDayOfWeek = N'Sunday'
))
Update dd set SrlWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND SrlWeekOfYr IS NULL 


--N'Wednesday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where  EnDayOfWeek = N'Wednesday' 
and ID >= (select Min(ID) from Dw.DimDate where  EnDayOfWeek = N'Sunday'
))
Update dd set SrlWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND SrlWeekOfYr IS NULL 


--N'Friday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where  EnDayOfWeek = N'Friday' 
and ID >= (select Min(ID) from Dw.DimDate where  EnDayOfWeek = N'Sunday'
))
Update dd set SrlWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND SrlWeekOfYr IS NULL 

--N'Saturday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where  EnDayOfWeek = N'Saturday' 
and ID >= (select Min(ID) from Dw.DimDate where  EnDayOfWeek = N'Sunday'
))
Update dd set SrlWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND SrlWeekOfYr IS NULL 








--N'Saturday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where  EnDayOfWeek = N'Saturday' 
and ID >= (select Min(ID) from Dw.DimDate where EnDayOfWeek = N'saturday'
))
Update dd set FrSrlWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND FrSrlWeekOfYr IS NULL 

--N'Sunday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where EnDayOfWeek = N'Sunday' 
and ID >= (select Min(ID) from Dw.DimDate where EnDayOfWeek = N'saturday'
))
Update dd set FrSrlWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND FrSrlWeekOfYr IS NULL 

--N'Monday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where  EnDayOfWeek = N'Monday' 
and ID >= (select Min(ID) from Dw.DimDate where  EnDayOfWeek = N'saturday'
))
Update dd set FrSrlWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND FrSrlWeekOfYr IS NULL 

--N'Tuesday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where  EnDayOfWeek = N'Tuesday' 
and ID >= (select Min(ID) from Dw.DimDate where  EnDayOfWeek = N'saturday'
))
Update dd set FrSrlWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND FrSrlWeekOfYr IS NULL 

--N'Thursday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where  EnDayOfWeek = N'Thursday' 
and ID >= (select Min(ID) from Dw.DimDate where  EnDayOfWeek = N'saturday'
))
Update dd set FrSrlWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND FrSrlWeekOfYr IS NULL 


--N'Wednesday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where  EnDayOfWeek = N'Wednesday' 
and ID >= (select Min(ID) from Dw.DimDate where  EnDayOfWeek = N'saturday'
))
Update dd set FrSrlWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND FrSrlWeekOfYr IS NULL 


--N'Friday' 
;With Stp1 as (select ROW_NUMBER() over(order by ID) Rn,ID from  Dw.DimDate where  EnDayOfWeek = N'Friday' 
and ID >= (select Min(ID) from Dw.DimDate where  EnDayOfWeek = N'saturday'
))
Update dd set FrSrlWeekOfYr = Rn from DW.DimDate dd inner join Stp1 s on s.ID = dd.ID AND FrSrlWeekOfYr IS NULL 








--آی دی اولین روز هفته رو بهشون بده
;with a as (
select ID,Frdt,FrDayOfWeek,FIRST_VALUE(ID)over(partition by FrSrlWeekOfYr order by id)FrstDay from dw.dimdate )
Update d set FrFrstWkDayID = FrstDay from a inner join dw.DimDate d on d.ID = a.id 


-- تعطیلات
Update d set IsHoliday = 1,HolidayDesc = h.Description 
	from dw.DimDate d inner join DimDateHoliday H on 
	h.Day = case when h.Hejri = 1 then d.HjDay else d.FrDay end and h.Month = case when h.Hejri = 1 then d.HjMonth else d.FrMonth end
	and IsHoliday is null 

Update 	dw.DimDate  set IsHoliday = 1 where FrNoDayOfWeek = 7 and IsHoliday is null 


-- آخرین روز ماه رو فلگ کن
;with a as 
(
	select *,max(FrDay) over(partition by Fryear,frmonth) as E from StockMarketDW.dw.DimDate
)
Update a set 
isendofmonth = 1 
from a where e = frday 



--================= شناسایی کبیسه
;with stp1 as 
(
	select FrYear from dw.DimDate where FrMonth = 12 and FrDay = 30
)
Update d1 
set FrIsLeap = 1 
from DW.DimDate D1 inner join stp1 s on s.FrYear = d1.FrYear 

Update  DW.DimDate 
set FrIsLeap = 0 
where FrIsLeap is null 

;with stp1 as 
(
	select EnYear,Count(1) Cnt from dw.DimDate 
	group by EnYear
	Having Count(1) = 366
)
Update d1 
set EnIsLeap = 1 
from DW.DimDate D1 inner join stp1 s on s.EnYear = d1.EnYear 

Update  DW.DimDate 
set EnIsLeap = 0 
where EnIsLeap is null 


END



