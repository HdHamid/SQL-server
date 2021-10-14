# Use DimDate smartly

## One friend comes to me and ask for a solution to generate multiple records for each record in a table that has StartDate and EndDate with monthly steps between them.  
You can use of DimDate that I left it [here](FillDimDate.sql) before


```bash

-- DimDate preparing .. 
Drop table if exists #Stp00
;WITH STP1 AS 
(
	SELECT DISTINCT FrYear+FrMonth as PersianYearMonthInt FROM StockMarketDW.DW.DimDate
)
SELECT ROW_NUMBER() OVER(ORDER BY PersianYearMonthInt) AS SeqPersianYearMonth,* INTO #Stp00 FROM STP1

alter table StockMarketDW.DW.DimDate
add SeqPersianYearMonth int 

Update sc set SeqPersianYearMonth = e.SeqPersianYearMonth 
from #Stp00 e inner join StockMarketDW.DW.DimDate sc on FrYear+FrMonth = e.PersianYearMonthInt

------================================================ 

drop table if exists #DimDate
select Frdt as PERSIANDATE ,FrDay as PersianDay,SeqPersianYearMonth,SeqID
into #DimDate from StockMarketDW.DW.DimDate


Create Clustered index iX ON #DimDate(PERSIANDATE)


drop table if exists #Dtable

create table #Dtable 
(
	ID int identity(1,1),
	StartDate char(10),
	EndDate char(10),
	Jumper int 
)

insert into #Dtable (StartDate,EndDate,Jumper)
VALUES 
	('1400/01/01','1401/01/01', 1),
	('1400/02/04','1401/05/03', 1),
	('1400/03/08','1401/09/06', 2),
	('1400/02/08','1402/09/06', 3)



drop table if exists #Stp1 
;with stp1 as 
(
  select t.*,cast(right(StartDate,2) as int) as StartDay,d.SeqPersianYearMonth from #Dtable t inner join #DimDate d on t.StartDate  = d.PersianDate 
)
select ROW_NUMBER() over(partition by t.id order by d.PersianDate) as RowNo,t.*,d.PersianDate 
	into #Stp1 
	from stp1 t 
	inner join #DimDate d on d.PERSIANDATE  between t.StartDate and t.EndDate and d.PersianDay = t.StartDay 
	and (d.SeqPersianYearMonth-t.SeqPersianYearMonth)%t.Jumper = 0


DROP TABLE IF EXISTS #Stp2
SELECT RowNo,ID,StartDate,EndDate,Jumper,StartDay,SeqPersianYearMonth,PersianDate INTO #STP2 FROM #Stp1
UNION ALL 
SELECT MAX(RowNo)+1,ID,StartDate,EndDate,Jumper,StartDay,SeqPersianYearMonth,EndDate AS PersianDate FROM #Stp1 s1 
WHERE NOT EXISTS(SELECT * FROM #Stp1 s2 WHERE PersianDate = EndDate AND s1.ID = s2.ID)
GROUP BY ID,StartDate,EndDate,Jumper,StartDay,SeqPersianYearMonth

CREATE CLUSTERED INDEX IX ON #Stp2 (ID,RowNo)

DROP TABLE IF EXISTS #Res1
;WITH stp3 AS 
(
	SELECT S2.ROWNO,S2.ID,S2.StartDate,S2.EndDate,S2.Jumper,S2.PersianDate AS WindowFrom
	,LEAD(PersianDate) OVER(PARTITION BY ID ORDER BY ROWNO) AS WindowTo FROM #Stp2 S2 
)
SELECT S3.ID,S3.RowNo,S3.StartDate,S3.EndDate,S3.Jumper,S3.WindowFrom,S3.WindowTo,COUNT(1) AS DaysBetween 
	INTO #Res1
FROM stp3 s3 
	INNER JOIN #DimDate D ON D.PersianDate BETWEEN S3.WindowFrom AND S3.WindowTo AND WindowTo IS NOT NULL 
GROUP BY S3.ID,S3.RowNo,S3.StartDate,S3.EndDate,S3.Jumper,S3.WindowFrom,S3.WindowTo
ORDER BY S3.ID,S3.RowNo


-- If it is supposed to be not equal to the next row
select r.ID,r.RowNo,r.StartDate,r.EndDate,r.DaysBetween - 1 as DaysBetween,r.Jumper,r.WindowFrom,iif(EndDate = WindowTo , WindowTo , d2.PERSIANDATE) WindowTo 
from #Res1 r 
	inner join #DimDate d on r.WindowTo = d.PERSIANDATE 
	inner join #DimDate d2 on d2.SeqID = d.SeqID - 1 
ORDER BY r.ID,r.RowNo

```
