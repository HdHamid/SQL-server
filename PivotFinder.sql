DROP TABLE IF EXISTS #PIVOT

DROP TABLE IF EXISTS #TBCUR
SELECT ROW_NUMBER()OVER(ORDER BY cast([Time] as DateTime)) AS RowNo
	,IIF([Open] > [Close] , [Open] , [Close] ) as CandleCeiling
	,IIF([Open] > [Close] , [Close] , [Open] ) as CandleFloor
,h.[Close],h.DateID,h.High,h.Low,h.[Open],h.Volume,h.Time
INTO #TBCUR 
FROM  [dbo].[EURUSD_H1] h

declare @untilRowNo int = (select Max(RowNo) from  #TBCUR) - 23

DECLARE @DegreeScaler decimal(6,5) = 0.009803

;with stp1 as 
(
	select *
	,max(CandleCeiling) over(order by RowNo rows between 23 preceding and 23 following) as MaxBetween  -- Bazeye 23 + 23 baraye shenasaee Price pivot MAX  
	,Min(CandleFloor) over(order by RowNo rows between 23 preceding and 23 following) as MinBetween 	-- Bazeye 23 + 23 baraye shenasaee Price pivot MIN  
	from #TBCUR	
) 
, stp2 as 
(
	select stp1.*,dt.Endt,iif(MaxBetween=CandleCeiling or RowNo = @untilRowNo,1,0) as MX ,iif(minBetween=CandleFloor or RowNo = @untilRowNo,1,0) as Min,dt.EnDay,dt.EnMonthName,dt.EnYear -- Shenasaee tarikhe PivotHa
	,iif(MaxBetween=High,1,0) as IsMXBecauseOfMaxBetween,iif(minBetween=High,1,0)IsMinBecauseOfMinBetween
	from stp1 
	inner join StockMarketDW.dw.DimDate dt on dt.ID = stp1.DateID
) 
,stp3 as 
(
	select * 
	,lag(MaxBetween) over(order by RowNo) as lgMax  --Ruye Har Pivot MAX Meghdare Pivot MAX Ghabli ro miarim
	,lag(RowNo) over(order by RowNo) as lgRowNoMax
	,RowNo - lag(RowNo) over(order by RowNo) as DiffMaxCount -- tedad ruzhaye beyne 2 pivot
	from stp2 where mx = 1 
)
,stp4 as 
(
	select * 
	,lag(MinBetween) over(order by RowNo) as LgMin --Ruye Har Pivot MIN Meghdare Pivot MIN Ghabli ro miarim
	,lag(RowNo) over(order by RowNo) as lgRowNoMin
	,RowNo - lag(RowNo) over(order by RowNo) as DiffMinCount  -- tedad ruzhaye beyne 2 pivot
	from stp2 where Min = 1 	
)
,stp5 as 
(
	select s2.*
	,s3.lgMax,s4.LgMin
	,s2.RowNo -s3.lgRowNoMax as CandleDiffFromLagMaxPivot,s2.RowNo - s4.lgRowNoMin as CandleDiffFromLagMinPivot
	,IIF( s3.DiffMaxCount>0,degrees(atn2((s3.CandleCeiling-s3.lgMax)/nullif((s3.CandleCeiling*@DegreeScaler),0),s3.DiffMaxCount)),NULL)  as PivotToPivotMaxDegree
	,IIF( s4.DiffMinCount>0,degrees(atn2((s4.CandleFloor-s4.LgMin)/nullif((s4.CandleFloor*@DegreeScaler),0),s4.DiffMinCount))  ,NULL) as PivotToPivotMinDegree
	,IIF( s2.RowNo -s3.lgRowNoMax>0,degrees(atn2((s2.CandleCeiling-s3.lgMax)/nullif((s2.CandleCeiling*@DegreeScaler),0),s2.RowNo -s3.lgRowNoMax)),NULL)  as PivotToCurrentMaxDegree
	,IIF( s2.RowNo -s4.lgRowNoMin>0,degrees(atn2((s2.CandleFloor-s4.LgMin)/nullif((s2.CandleFloor*@DegreeScaler),0),s2.RowNo -s4.lgRowNoMin))  ,NULL) as PivotToCurrentMinDegree	
	from stp2 s2 
		LEFT join stp3 s3 on s2.RowNo between s3.lgRowNoMax+1 and s3.RowNo
		LEFT join stp4 s4 on s2.RowNo between s4.lgRowNoMin+1 and s4.RowNo
)
select 
RowNo
,[Time]
,[Open]
,[High]
,[Low]
,[Close]
,CandleCeiling
,CandleFloor
,Volume
,DateID
,MaxBetween
,MinBetween
,Endt
,iif(RowNo = @untilRowNo and IsMXBecauseOfMaxBetween = 0 , 0 ,MX) as MX
,iif(RowNo = @untilRowNo and IsMinBecauseOfMinBetween = 0 , 0 ,min) as Min
,EnDay
,EnMonthName
,EnYear
,lgMax
,LgMin
,[close] - LgMin AS ClosePriceDiffLgMin
,LgMax - [close] AS ClosePriceDiffLgMax
,[High] - LgMin AS HighPriceDiffLgMin
,LgMax - [High] AS HighPriceDiffLgMax
,[Low] - LgMin AS LowPriceDiffLgMin
,LgMax - [Low] AS LowPriceDiffLgMax
,CandleDiffFromLagMaxPivot
,CandleDiffFromLagMinPivot
,PivotToPivotMaxDegree
,PivotToPivotMinDegree
,PivotToCurrentMaxDegree
,PivotToCurrentMinDegree
, CAST(NULL AS DECIMAL(6,4)) AS VolLagPercent
INTO #PIVOT 
from stp5 S
where  RowNo <= @untilRowNo
