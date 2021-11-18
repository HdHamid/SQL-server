# A table with formula records
A few days ago one of my friends come to me and asked about a solution for a table with many formula records and a table with values for each placeholder in formulas,
then he wanted to know how to calculate the result as a new column in front of each record

Here you can see the question: 
```bash
Qid         CalcType
----------- --------------------------------------
1           <1400>/<IND1400>
2           <1700>/(<1027>-<1018>-<1019>+<1700>)



Code                                               val
-------------------------------------------------- ---------------------------------------
<1400>                                             100.00
<IND1400>                                          50.00
<1700>                                             30.00
<1027>                                             30.00
<1018>                                             10.00
<1019>                                             10.00

```

```bash 
drop table if exists #CalcType
Create table #CalcType 
(
	Qid int identity(1,1),
	CalcType varchar(500)
)

insert into #CalcType (CalcType)
VALUES
('<1400>/<IND1400>'),
('<1700>/(<1027>-<1018>-<1019>+<1700>)')

drop table if exists #CodVal
Create table #CodVal 
(
	Code varchar(50),
	val decimal(38,2)
)

insert into #CodVal (Code,val)
VALUES
('<1400>',100),
('<IND1400>',50),
('<1700>',30),
('<1027>',30),
('<1018>',10),
('<1019>',10)
```

Now here is the answer: 
Join each placeholder with its place in the formula

```bash
Drop table if exists #R
SELECT ROW_NUMBER()over(partition by t.Qid order by (select 1)) as Rn,
*
into #R
	FROM #CalcType t
	inner join #CodVal v on t.CalcType like '%'+v.Code+'%'
```

Replace all values in formulas 
```bash
drop table if exists #MaxRn
select Qid,max(rn) as MaxRn into #MaxRn from #R
group by Qid

drop table if exists #fins
;with stp1 as 
(
	select *,REPLACE(CalcType,Code,val) as Res from #R where rn = 1 
	union all 
	select r.rn,r.Qid,r.CalcType,r.Code,r.val ,REPLACE(s.Res,r.Code,r.val)
	from #r r inner join stp1 s on r.Qid = s.Qid and s.Rn+1 = r.Rn
)
select s.Qid,s.CalcType,s.Res into #fins
from stp1 s inner join #MaxRn m on m.Qid = s.Qid and m.MaxRn = s.Rn
``` 

Create a dynamic query to calculate the results
```bash
declare @Query nvarchar(MAX) = N''

select @Query += 'select '+Cast(Qid as Nvarchar(50))+' as Qid,'''+CalcType+''' as CalcType,'''+Res+''' as ResChar,'+Res+' as Res
	union all '
from #fins

set @Query = stuff(@Query,len(@Query)-11,12,'')

exec (@Query)



```

