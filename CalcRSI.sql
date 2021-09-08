
drop table if exists #tbl
Create table #tbl (Rn int,RowNo int,ClosePrc decimal(26,6),Vol decimal(26,6),Chng decimal(26,6))



insert into #tbl(rn,RowNo,ClosePrc,Vol,Chng)
select RowNo AS Rn,e.RowNo,e.[Close],e.Volume,e.[Close] - LAG(e.[Close]) over(Order by RowNo) Chngs
from #TBCUR e

CREATE CLUSTERED INDEX IX ON #tbl (Rn)


drop table if exists #ee
create table #ee (Rn int,RowNo int,ClosePrc decimal(26,6),Vol Decimal(26,6),Chng decimal(26,6),GainAvg decimal(26,6),LossAvg decimal(26,6),Prmtr int)

declare @days int = 14 

declare @Q nvarchar(Max) = N';with a as (
select *, 
sum(case when Chng > 0 then Chng else 0 end) over(order by RowNo Rows '+cast(@days-1 as nvarchar(50))+' Preceding) / '+cast(@days as nvarchar(50))+'  as GainAvg,
sum(case when Chng < 0 then abs(Chng) else 0 end) over(order by RowNo Rows '+cast(@days-1 as nvarchar(50))+' Preceding) / '+cast(@days as nvarchar(50))+' as LossAvg 
from #tbl where rn <= '+cast(@days+1 as nvarchar(50))+'
Union all 
select t.* 
, (a.GainAvg * '+cast(@days-1 as nvarchar(50))+' + case when t.Chng > 0.0 then t.Chng else 0.0 end) / '+cast(@days as nvarchar(50))+'
, (a.LossAvg * '+cast(@days-1 as nvarchar(50))+' + case when t.Chng < 0.0 then abs(t.Chng) else 0.0 end) / '+cast(@days as nvarchar(50))+'
from #tbl t 
inner join a on t.Rn = a.Rn + 1 and t.Rn > '+cast(@days+1 as nvarchar(50))+')
select *,'+cast(@days as nvarchar(50))+' as Prmtr from a option (maxrecursion 0)'
insert into #ee(Rn,RowNo,ClosePrc,Vol,Chng,GainAvg,LossAvg,Prmtr)
exec (@Q)


set @days = 5 

set @Q  = N';with a as (
select *, 
sum(case when Chng > 0 then Chng else 0 end) over(order by RowNo Rows '+cast(@days-1 as nvarchar(50))+' Preceding) / '+cast(@days as nvarchar(50))+'  as GainAvg,
sum(case when Chng < 0 then abs(Chng) else 0 end) over(order by RowNo Rows '+cast(@days-1 as nvarchar(50))+' Preceding) / '+cast(@days as nvarchar(50))+' as LossAvg 
from #tbl where rn <= '+cast(@days+1 as nvarchar(50))+'
Union all 
select t.* 
, (a.GainAvg * '+cast(@days-1 as nvarchar(50))+' + case when t.Chng > 0 then t.Chng else 0 end) / '+cast(@days as nvarchar(50))+'
, (a.LossAvg * '+cast(@days-1 as nvarchar(50))+' + case when t.Chng < 0 then abs(t.Chng) else 0 end) / '+cast(@days as nvarchar(50))+'
from #tbl t 
inner join a on t.Rn = a.Rn + 1 and t.Rn > '+cast(@days+1 as nvarchar(50))+')
select *,'+cast(@days as nvarchar(50))+' as Prmtr  from a option (maxrecursion 0)'
insert into #ee(Rn,RowNo,ClosePrc,Vol,Chng,GainAvg,LossAvg,Prmtr)
exec (@Q)


DROP TABLE IF EXISTS #AfterRsi

;with Stp1 as 
(
select *
	,case when LossAvg = 0 then NULL else GainAvg/LossAvg end as RS
	,case when LossAvg = 0 then 100 else 100 - (100/(1+(GainAvg/LossAvg))) end RSI
from #ee
) 
select p.*,s.RSI as RSI14,s2.RSI as RSI5
INTO #AfterRsi
from Stp1 s 
	inner join #PIVOT p on p.RowNo = s.RowNo and s.Prmtr = 14
	inner join Stp1 s2 on p.RowNo = s2.RowNo and s2.Prmtr = 5
